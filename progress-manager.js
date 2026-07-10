/* ============================================================
   MoneyMuncher Progress Manager (plain JS — no modules)
   Works offline immediately. Cloud works only if you add the
   3 Firebase CDN scripts (see HTML below).
   ============================================================ */

(function (window) {
  "use strict";

  /* --- 1. LOCALSTORAGE (always works, even offline) --- */
  var STORAGE_KEY = "mm_progress_v2";

  var DEFAULT_PROGRESS = {
    coins: 30,
    saved: 0,
    joy: 50,
    wisdom: 0,
    level: 1,
    badges: [],
    currentLevel: 0,
    unlockedLevel: 0,
    completedLevels: [],
    completedLessons: [],
    shopBadges: [],
    transactions: []
  };

  function clone(obj) {
    return JSON.parse(JSON.stringify(obj));
  }

  function getLocal() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return clone(DEFAULT_PROGRESS);
      return Object.assign({}, clone(DEFAULT_PROGRESS), JSON.parse(raw));
    } catch (e) {
      console.error("[MM] localStorage read failed", e);
      return clone(DEFAULT_PROGRESS);
    }
  }

  function setLocal(data) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
    } catch (e) {
      console.error("[MM] localStorage write failed", e);
    }
  }

  /* --- 2. SAVE-CODE COMPRESSION --- */
  // Map badge names -> tiny numbers so the code stays short
  var BADGE_ENCODE = {
    "first-save": 1,
    "penny-wise": 2,
    "big-spender": 3,
    "level-5": 4,
    "level-10": 5,
    "joy-master": 6,
    "wisdom-10": 7,
    "completed": 8
  };
  var BADGE_DECODE = {};
  for (var k in BADGE_ENCODE) BADGE_DECODE[BADGE_ENCODE[k]] = k;

  function exportSaveCode(progress) {
    var payload = [
      1, // format version
      progress.coins,
      progress.saved,
      progress.joy,
      progress.wisdom,
      progress.level
    ];
    for (var i = 0; i < progress.badges.length; i++) {
      var num = BADGE_ENCODE[progress.badges[i]];
      if (num) payload.push(num);
    }
    var json = JSON.stringify(payload);
    var bytes = [];
    for (var i = 0; i < json.length; i++) bytes.push(json.charCodeAt(i));
    var csum = bytes.reduce(function (a, b) { return a + b; }, 0) & 0xFF;

    // Build binary string: [versionByte, checksumByte, ...jsonBytes]
    var bin = String.fromCharCode(1, csum);
    for (var i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);

    try {
      var b64 = btoa(bin).replace(/=+$/, "").toUpperCase();
      return b64.match(/.{1,4}/g).join("-");
    } catch (e) {
      return "";
    }
  }

  function importSaveCode(code) {
    try {
      var raw = (code || "").replace(/-/g, "").replace(/ /g, "");
      if (!raw) return null;

      // restore base64 padding
      var pad = raw + "===".slice((raw.length + 3) % 4);
      var bin = atob(pad);

      var version = bin.charCodeAt(0);
      if (version !== 1) return null;

      var csum = bin.charCodeAt(1);
      var jsonStr = "";
      var sumCheck = 0;
      for (var i = 2; i < bin.length; i++) {
        jsonStr += bin[i];
        sumCheck += bin.charCodeAt(i);
      }
      if ((sumCheck & 0xFF) !== csum) {
        console.warn("[MM] Save code checksum failed (typo?)");
        return null;
      }

      var arr = JSON.parse(jsonStr);
      var out = {
        coins:  Number(arr[1]) || 0,
        saved:  Number(arr[2]) || 0,
        joy:    Number(arr[3]) || 0,
        wisdom: Number(arr[4]) || 0,
        level:  Number(arr[5]) || 1,
        badges: []
      };
      for (var i = 6; i < arr.length; i++) {
        if (BADGE_DECODE[arr[i]]) out.badges.push(BADGE_DECODE[arr[i]]);
      }
      return out;
    } catch (e) {
      console.error("[MM] Invalid save code", e);
      return null;
    }
  }

  /* --- 3. OPTIONAL FIREBASE CLOUD LAYER --- */
  var cloud = {
    ready: false,
    user: null,
    auth: null,
    db: null
  };

  function initCloud(config) {
    if (typeof firebase === "undefined") {
      console.warn("[MM] Firebase SDK not found. Running offline only.");
      return;
    }
    try {
      if (!firebase.apps.length) firebase.initializeApp(config);
      cloud.ready = true;
      cloud.auth = firebase.auth();
      cloud.db = firebase.firestore();

      cloud.auth.onAuthStateChanged(function (user) {
        cloud.user = user;
        if (user) {
          console.log("[MM] Cloud user:", user.uid);
          pullCloud();
        } else {
          console.log("[MM] Cloud signed out");
        }
      });
    } catch (e) {
      console.error("[MM] Firebase init failed", e);
      cloud.ready = false;
    }
  }

  function getProfile() {
    try {
      return JSON.parse(localStorage.getItem("moneymuncherSession") || "null") || {};
    } catch (e) {
      return {};
    }
  }

  function pushCloud() {
    if (!cloud.ready || !cloud.user) return;
    var p = getLocal();
    var profile = getProfile();
    var payload = Object.assign({}, p, {
      uid: cloud.user.uid,
      email: cloud.user.email || profile.email || "",
      name: profile.name || (cloud.user.email ? cloud.user.email.split("@")[0] : ""),
      role: profile.role || "Player",
      betaInterest: Boolean(profile.betaInterest),
      signupSource: profile.signupSource || "",
      platformInterest: profile.platformInterest || "",
      betaJoinedAt: profile.betaJoinedAt || "",
      authProvider: cloud.user.isAnonymous ? "anonymous" : "password",
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });

    cloud.db.collection("players").doc(cloud.user.uid).set(payload, { merge: true })
      .catch(function (e) {
        console.error("[MM] Cloud save failed", e);
      });
  }

  function pullCloud() {
    if (!cloud.ready || !cloud.user) return;
    cloud.db.collection("players").doc(cloud.user.uid).get().then(function (doc) {
      if (doc.exists) {
        var data = doc.data();
        var local = getLocal();

        // Merge rule: highest numbers win, union badges
        var merged = {
          coins: Math.max(local.coins, data.coins || 0),
          saved: Math.max(local.saved, data.saved || 0),
          joy: Math.max(local.joy, data.joy || 0),
          wisdom: Math.max(local.wisdom, data.wisdom || 0),
          level: Math.max(local.level, data.level || 1),
          badges: union(local.badges || [], data.badges || []),
          currentLevel: Math.max(local.currentLevel || 0, data.currentLevel || 0),
          unlockedLevel: Math.max(local.unlockedLevel || 0, data.unlockedLevel || 0),
          completedLevels: union(local.completedLevels || [], data.completedLevels || []),
          completedLessons: union(local.completedLessons || [], data.completedLessons || []),
          shopBadges: union(local.shopBadges || [], data.shopBadges || []),
          transactions: (local.transactions || []).concat(data.transactions || []).slice(-80)
        };
        setLocal(merged);
        if (data.email || data.name || data.role) {
          localStorage.setItem("moneymuncherSession", JSON.stringify({
            id: cloud.user.uid,
            email: data.email || cloud.user.email || "",
            name: data.name || (cloud.user.email ? cloud.user.email.split("@")[0] : "Player"),
            role: data.role || "Player",
            betaInterest: Boolean(data.betaInterest),
            signupSource: data.signupSource || "",
            platformInterest: data.platformInterest || "",
            betaJoinedAt: data.betaJoinedAt || ""
          }));
        }
        console.log("[MM] Cloud progress merged into local");
      } else {
        // First time: seed cloud with what they have locally
        pushCloud();
      }
    }).catch(function (e) {
      console.error("[MM] Cloud load failed", e);
    });
  }

  function union(a, b) {
    var out = a.slice();
    for (var i = 0; i < b.length; i++) {
      if (out.indexOf(b[i]) === -1) out.push(b[i]);
    }
    return out;
  }

  /* --- 4. PUBLIC API --- */
  window.MoneyMuncher = {
    // ---- Setup ----
    init: function (opts) {
      opts = opts || {};
      if (opts.firebaseConfig) initCloud(opts.firebaseConfig);
      console.log("[MM] Initialized. Cloud:", cloud.ready ? "ON" : "OFF");
    },

    // ---- Progress (always hits localStorage; syncs cloud in background) ----
    get: function () { return clone(getLocal()); },

    set: function (obj) {
      var next = Object.assign({}, getLocal(), obj);
      setLocal(next);
      if (cloud.ready && cloud.user) pushCloud();
    },

    reset: function () { setLocal(clone(DEFAULT_PROGRESS)); },

    setProfile: function (profile) {
      profile = profile || {};
      var existing = getProfile();
      var next = {
        id: profile.id || existing.id || (cloud.user && cloud.user.uid) || "",
        email: profile.email || existing.email || (cloud.user && cloud.user.email) || "",
        name: profile.name || existing.name || "",
        role: profile.role || existing.role || "Player",
        betaInterest: (typeof profile.betaInterest === "boolean") ? profile.betaInterest : Boolean(existing.betaInterest),
        signupSource: profile.signupSource || existing.signupSource || "",
        platformInterest: profile.platformInterest || existing.platformInterest || "",
        betaJoinedAt: profile.betaJoinedAt || existing.betaJoinedAt || ""
      };
      localStorage.setItem("moneymuncherSession", JSON.stringify(next));
      if (cloud.ready && cloud.user) pushCloud();
      return next;
    },

    getUser: function () {
      if (!cloud.user) return null;
      var profile = getProfile();
      return {
        uid: cloud.user.uid,
        email: cloud.user.email || profile.email || "",
        name: profile.name || "",
        role: profile.role || "Player",
        betaInterest: Boolean(profile.betaInterest),
        signupSource: profile.signupSource || "",
        platformInterest: profile.platformInterest || "",
        betaJoinedAt: profile.betaJoinedAt || ""
      };
    },
    addCoins:  function (n) { var p = this.get(); this.set({ coins: p.coins + n }); },
    addSaved:  function (n) { var p = this.get(); this.set({ saved: p.saved + n }); },
    addJoy:    function (n) { var p = this.get(); this.set({ joy: Math.min(100, p.joy + n) }); },
    addWisdom: function (n) { var p = this.get(); this.set({ wisdom: p.wisdom + n }); },
    levelUp:   function ()  { var p = this.get(); this.set({ level: p.level + 1 }); },
    addBadge:  function (b) { var p = this.get(); this.set({ badges: union(p.badges, [b]) }); },

    addTransaction: function (type, amount, source, reason) {
      var p = this.get();
      var tx = {
        id: "tx_" + Date.now() + "_" + Math.random().toString(16).slice(2),
        type: type,
        amount: Number(amount) || 0,
        source: source || "money-muncher",
        reason: reason || "",
        createdAt: new Date().toISOString()
      };
      this.set({ transactions: (p.transactions || []).concat([tx]).slice(-80) });
      return tx;
    },

    earnCoins: function (amount, source, reason) {
      var n = Math.max(0, Math.round(Number(amount) || 0));
      if (!n) return false;
      var p = this.get();
      this.set({
        coins: (p.coins || 0) + n,
        lifetimeCoinsEarned: (p.lifetimeCoinsEarned || 0) + n,
        transactions: (p.transactions || []).concat([{
          id: "tx_" + Date.now() + "_" + Math.random().toString(16).slice(2),
          type: "earn",
          amount: n,
          source: source || "quest",
          reason: reason || "Coins earned",
          createdAt: new Date().toISOString()
        }]).slice(-80)
      });
      return true;
    },

    spendCoins: function (amount, source, reason) {
      var n = Math.max(0, Math.round(Number(amount) || 0));
      var p = this.get();
      if (!n || (p.coins || 0) < n) return false;
      this.set({
        coins: (p.coins || 0) - n,
        lifetimeCoinsSpent: (p.lifetimeCoinsSpent || 0) + n,
        transactions: (p.transactions || []).concat([{
          id: "tx_" + Date.now() + "_" + Math.random().toString(16).slice(2),
          type: "spend",
          amount: n,
          source: source || "shop",
          reason: reason || "Coins spent",
          createdAt: new Date().toISOString()
        }]).slice(-80)
      });
      return true;
    },

    buyBadge: function (badge) {
      if (!badge || !badge.id) return { ok: false, message: "Badge not found." };
      var p = this.get();
      var owned = union(p.shopBadges || [], p.badges || []);
      if (owned.indexOf(badge.id) !== -1) return { ok: false, message: "You already own this badge." };
      if ((p.coins || 0) < badge.price) return { ok: false, message: "Save more coins for this badge." };
      var nextShopBadges = union(p.shopBadges || [], [badge.id]);
      var nextBadges = union(p.badges || [], [badge.id]);
      this.set({
        coins: (p.coins || 0) - badge.price,
        lifetimeCoinsSpent: (p.lifetimeCoinsSpent || 0) + badge.price,
        shopBadges: nextShopBadges,
        badges: nextBadges,
        transactions: (p.transactions || []).concat([{
          id: "tx_" + Date.now() + "_" + Math.random().toString(16).slice(2),
          type: "spend",
          amount: badge.price,
          source: "badge-shop",
          reason: "Bought " + badge.name,
          createdAt: new Date().toISOString()
        }]).slice(-80)
      });
      return { ok: true, message: badge.name + " added to your badge board." };
    },

    // ---- Save Codes ----
    exportCode: function () { return exportSaveCode(this.get()); },

    importCode: function (code) {
      var imp = importSaveCode(code);
      if (!imp) return false;
      var local = this.get();
      var merged = {
        coins:  Math.max(local.coins,  imp.coins),
        saved:  Math.max(local.saved,  imp.saved),
        joy:    Math.max(local.joy,    imp.joy),
        wisdom: Math.max(local.wisdom, imp.wisdom),
        level:  Math.max(local.level,  imp.level),
        badges: union(local.badges, imp.badges)
      };
      this.set(merged);
      return true;
    },

    // ---- Auth / Sign Up / Sign In (requires Firebase CDN) ----
    signUp: function (email, password, profile) {
      return new Promise(function (resolve, reject) {
        if (!cloud.ready) return reject(new Error("Cloud not initialized"));
        cloud.auth.createUserWithEmailAndPassword(email, password)
          .then(function (cred) {
            cloud.user = cred.user;
            window.MoneyMuncher.setProfile({
              id: cred.user.uid,
              email: cred.user.email,
              name: profile && profile.name ? profile.name : cred.user.email.split("@")[0],
              role: profile && profile.role ? profile.role : "Player",
              betaInterest: Boolean(profile && profile.betaInterest),
              signupSource: profile && profile.signupSource ? profile.signupSource : "",
              platformInterest: profile && profile.platformInterest ? profile.platformInterest : "",
              betaJoinedAt: profile && profile.betaJoinedAt ? profile.betaJoinedAt : ""
            });
            pushCloud(); // push current local progress immediately
            resolve({ uid: cred.user.uid, email: cred.user.email });
          })
          .catch(reject);
      });
    },

    signIn: function (email, password, profile) {
      return new Promise(function (resolve, reject) {
        if (!cloud.ready) return reject(new Error("Cloud not initialized"));
        cloud.auth.signInWithEmailAndPassword(email, password)
          .then(function (cred) {
            cloud.user = cred.user;
            if (profile && (profile.name || profile.role)) {
              window.MoneyMuncher.setProfile({
                id: cred.user.uid,
                email: cred.user.email,
                name: profile.name || cred.user.email.split("@")[0],
                role: profile.role || "Player",
                betaInterest: Boolean(profile.betaInterest),
                signupSource: profile.signupSource || "",
                platformInterest: profile.platformInterest || "",
                betaJoinedAt: profile.betaJoinedAt || ""
              });
            }
            resolve({ uid: cred.user.uid, email: cred.user.email });
            // pullCloud() will auto-fire via onAuthStateChanged
          })
          .catch(reject);
      });
    },

    signInAnonymous: function () {
      return new Promise(function (resolve, reject) {
        if (!cloud.ready) return reject(new Error("Cloud not initialized"));
        cloud.auth.signInAnonymously()
          .then(function (cred) { resolve({ uid: cred.user.uid }); })
          .catch(reject);
      });
    },

    resetPassword: function (email) {
      return new Promise(function (resolve, reject) {
        if (!cloud.ready) return reject(new Error("Cloud not initialized"));
        cloud.auth.sendPasswordResetEmail(email)
          .then(resolve)
          .catch(reject);
      });
    },

    signOut: function () {
      if (!cloud.ready) return Promise.resolve();
      return cloud.auth.signOut();
    },

    isLoggedIn: function () { return !!(cloud.ready && cloud.user); }
  };

})(window);
