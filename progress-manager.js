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
  // game map fields
  currentLevel: 0,
  unlockedLevel: 0,
  completedLevels: []
};

  function clone(obj) {
    return JSON.parse(JSON.stringify(obj));
  }

  function getLocal() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return clone(DEFAULT_PROGRESS);
      return JSON.parse(raw);
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

  function pushCloud() {
    if (!cloud.ready || !cloud.user) return;
    var p = getLocal();
    cloud.db.collection("players").doc(cloud.user.uid).set({
      coins: p.coins,
      saved: p.saved,
      joy: p.joy,
      wisdom: p.wisdom,
      level: p.level,
      badges: p.badges,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    }).catch(function (e) {
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
          coins:  Math.max(local.coins,  data.coins  || 0),
          saved:  Math.max(local.saved,  data.saved  || 0),
          joy:    Math.max(local.joy,    data.joy    || 0),
          wisdom: Math.max(local.wisdom, data.wisdom || 0),
          level:  Math.max(local.level,  data.level  || 1),
          badges: union(local.badges, data.badges || [])
        };
        setLocal(merged);
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

    addCoins:  function (n) { var p = this.get(); this.set({ coins: p.coins + n }); },
    addSaved:  function (n) { var p = this.get(); this.set({ saved: p.saved + n }); },
    addJoy:    function (n) { var p = this.get(); this.set({ joy: Math.min(100, p.joy + n) }); },
    addWisdom: function (n) { var p = this.get(); this.set({ wisdom: p.wisdom + n }); },
    levelUp:   function ()  { var p = this.get(); this.set({ level: p.level + 1 }); },
    addBadge:  function (b) { var p = this.get(); this.set({ badges: union(p.badges, [b]) }); },

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
    signUp: function (email, password) {
      return new Promise(function (resolve, reject) {
        if (!cloud.ready) return reject(new Error("Cloud not initialized"));
        cloud.auth.createUserWithEmailAndPassword(email, password)
          .then(function (cred) {
            cloud.user = cred.user;
            pushCloud(); // push current local progress immediately
            resolve({ uid: cred.user.uid, email: cred.user.email });
          })
          .catch(reject);
      });
    },

    signIn: function (email, password) {
      return new Promise(function (resolve, reject) {
        if (!cloud.ready) return reject(new Error("Cloud not initialized"));
        cloud.auth.signInWithEmailAndPassword(email, password)
          .then(function (cred) {
            cloud.user = cred.user;
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

    signOut: function () {
      if (!cloud.ready) return Promise.resolve();
      return cloud.auth.signOut();
    },

    isLoggedIn: function () { return !!(cloud.ready && cloud.user); }
  };

})(window);
