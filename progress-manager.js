// ============================================================
// MONEY MUNCHER — Progress Manager
// Supports: localStorage (offline), Firebase, Supabase, & Save Codes
// ============================================================

/* -----------------------------------------------------------
   1. DEFAULTS & BADGE REGISTRY
   Add every badge your game awards so save codes stay tiny.
   ----------------------------------------------------------- */
const DEFAULT_PROGRESS = {
  coins: 30,
  saved: 0,
  joy: 50,
  wisdom: 0,
  level: 1,
  badges: []
};

// badgeName -> compact ID for save-code compression
const BADGE_ID = {
  "first-save":    1,
  "penny-wise":    2,
  "big-spender":   3,
  "level-5":       4,
  "level-10":      5,
  "joy-master":    6,
  "wisdom-10":     7,
  "saver-100":     8,
  "completed":     9,
  // ...add more as your game grows
};
const ID_BADGE = Object.fromEntries(
  Object.entries(BADGE_ID).map(([k, v]) => [v, k])
);

/* -----------------------------------------------------------
   2. LOCALSTORAGE OFFLINE LAYER
   ----------------------------------------------------------- */
const STORAGE_KEY = "moneymuncher_progress";
const SYNC_FLAG   = "moneymuncher_needs_cloud_sync";

function getLocal() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : structuredClone(DEFAULT_PROGRESS);
  } catch {
    return structuredClone(DEFAULT_PROGRESS);
  }
}

function setLocal(progress) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(progress));
  localStorage.setItem(SYNC_FLAG, "true");
}

/* -----------------------------------------------------------
   3. SAVE-CODE EXPORT / IMPORT (no backend required)
   Compact, copy-paste friendly, with built-in checksum.
   ----------------------------------------------------------- */

function packBytes(str) {
  return str.split("").map(c => c.charCodeAt(0));
}

function unpackBytes(arr) {
  return String.fromCharCode(...arr);
}

function checksum8(bytes) {
  return bytes.reduce((a, b) => a + b, 0) & 0xFF;
}

/**
 * Turns progress into a short dashed code like:
 *   WNNG-SZQX-F3TM-PL9R-VQ2
 */
export function exportSaveCode(progress) {
  // Compact array: [version, coins, saved, joy, wisdom, level, badgeIds...]
  const payload = [
    1, // save-code format version
    progress.coins,
    progress.saved,
    progress.joy,
    progress.wisdom,
    progress.level,
    ...progress.badges.map(b => BADGE_ID[b] || 0).filter(Boolean)
  ];
  const json = JSON.stringify(payload);
  const bytes = packBytes(json);
  const csum = checksum8(bytes);

  // [versionByte, checksumByte, ...jsonBytes]
  const full = new Uint8Array([1, csum, ...bytes]);
  const bin = unpackBytes(full);

  // btoa, strip padding, uppercase, chunk every 4
  const b64 = btoa(bin).replace(/=+$/, "").toUpperCase();
  return b64.match(/.{1,4}/g)?.join("-") || b64;
}

/**
 * Parses a save code. Returns null if invalid/corrupt.
 */
export function importSaveCode(code) {
  try {
    const raw = code.replace(/-/g, "").replace(/ /g, "");
    // restore padding for atob
    const pad = raw.padEnd(raw.length + ((4 - (raw.length % 4)) % 4), "=");
    const bin = atob(pad);
    const all = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) all[i] = bin.charCodeAt(i);

    const version = all[0];
    if (version !== 1) return null;

    const csum = all[1];
    const jsonBytes = all.slice(2);
    if (checksum8(jsonBytes) !== csum) {
      console.warn("Save code checksum failed — corrupted or typo.");
      return null;
    }

    const payload = JSON.parse(unpackBytes(jsonBytes));
    const [ , coins, saved, joy, wisdom, level, ...badgeIds] = payload;

    return {
      coins:   Number(coins)   || 0,
      saved:   Number(saved)   || 0,
      joy:     Math.min(100, Number(joy) || 0),
      wisdom:  Number(wisdom)  || 0,
      level:   Number(level)   || 1,
      badges:  badgeIds.map(id => ID_BADGE[id] || `unknown-${id}`)
    };
  } catch (e) {
    console.error("Bad save code", e);
    return null;
  }
}

/* -----------------------------------------------------------
   4. OPTIONAL CLOUD BACKENDS
   Uncomment & install the one you want.
   ----------------------------------------------------------- */

/* ===== Firebase =====
import { initializeApp } from "firebase/app";
import { getAuth, signInAnonymously, onAuthStateChanged } from "firebase/auth";
import { getFirestore, doc, setDoc, getDoc, onSnapshot } from "firebase/firestore";

class FirebaseBackend {
  userId = null;
  unsub = null;
  constructor(config) {
    const app = initializeApp(config);
    this.auth = getAuth(app);
    this.db   = getFirestore(app);
  }
  async loginAnon() {
    const { user } = await signInAnonymously(this.auth);
    this.userId = user.uid;
    return this.userId;
  }
  async push(progress) {
    if (!this.userId) return false;
    await setDoc(doc(this.db, "players", this.userId), {
      ...progress, updatedAt: Date.now()
    }, { merge: true });
    return true;
  }
  async pull() {
    if (!this.userId) return null;
    const s = await getDoc(doc(this.db, "players", this.userId));
    return s.exists() ? s.data() : null;
  }
  onChange(cb) {
    if (!this.userId) return;
    this.unsub = onSnapshot(doc(this.db, "players", this.userId), s => {
      if (s.exists()) cb(s.data());
    });
  }
  logout() { this.unsub?.(); this.userId = null; }
}
*/

/* ===== Supabase =====
import { createClient } from "@supabase/supabase-js";

class SupabaseBackend {
  userId = null;
  channel = null;
  constructor(url, key) {
    this.client = createClient(url, key);
  }
  async loginAnon() {
    const { data, error } = await this.client.auth.signInAnonymously();
    if (error) throw error;
    this.userId = data.user.id;
    return this.userId;
  }
  async push(progress) {
    if (!this.userId) return false;
    const { error } = await this.client
      .from("player_progress")
      .upsert({ user_id: this.userId, ...progress, updated_at: new Date().toISOString() });
    return !error;
  }
  async pull() {
    if (!this.userId) return null;
    const { data, error } = await this.client
      .from("player_progress").select("*").eq("user_id", this.userId).single();
    if (error || !data) return null;
    const { user_id, updated_at, id, ...rest } = data;
    return rest;
  }
  onChange(cb) {
    if (!this.userId) return;
    this.channel = this.client.channel(`player_${this.userId}`)
      .on("postgres_changes", {
        event: "*", schema: "public", table: "player_progress",
        filter: `user_id=eq.${this.userId}`
      }, p => cb(p.new))
      .subscribe();
  }
  logout() { this.client.removeChannel(this.channel); this.userId = null; }
}
*/

/* -----------------------------------------------------------
   5. SMART MANAGER (offline-first, cloud-sync, save-code ready)
   ----------------------------------------------------------- */
export class MoneyMuncherProgress {
  backend = null;
  cache   = structuredClone(DEFAULT_PROGRESS);

  constructor(backend = null) {
    this.backend = backend;
    this.cache = getLocal();
    if (backend) this._initCloud();
  }

  /* --- Public API --- */
  get()  { return structuredClone(this.cache); }
  set(p) { this.cache = { ...this.cache, ...p }; setLocal(this.cache); this._cloudPush(); }

  addCoins(n)  { this.set({ coins: this.cache.coins + n }); }
  addSaved(n)  { this.set({ saved: this.cache.saved + n }); }
  addJoy(n)    { this.set({ joy: Math.min(100, this.cache.joy + n) }); }
  addWisdom(n) { this.set({ wisdom: this.cache.wisdom + n }); }
  levelUp()    { this.set({ level: this.cache.level + 1 }); }
  addBadge(b)  { this.set({ badges: [...this.cache.badges, b] }); }

  /* --- Save Code Interface --- */
  exportCode() { return exportSaveCode(this.cache); }

  importCode(code) {
    const imported = importSaveCode(code);
    if (!imported) return false;
    // Merge carefully: badges union, higher values win where it makes sense
    const merged = {
      ...imported,
      // if local has a higher level, keep it (or swap logic if you prefer cloud-wins)
      level: Math.max(this.cache.level, imported.level),
      coins: Math.max(this.cache.coins, imported.coins),
      badges: [...new Set([...this.cache.badges, ...imported.badges])]
    };
    this.set(merged);
    return true;
  }

  /* --- Internal --- */
  async _initCloud() {
    try {
      await this.backend.loginAnon();
      const remote = await this.backend.pull();
      if (remote) {
        const needsSync = localStorage.getItem(SYNC_FLAG) === "true";
        if (needsSync) {
          await this.backend.push(this.cache);
        } else {
          this.cache = { ...DEFAULT_PROGRESS, ...remote };
          setLocal(this.cache);
        }
      } else {
        await this.backend.push(this.cache); // first-time cloud seed
      }
      this.backend.onChange((data) => {
        const { updatedAt, updated_at, ...progress } = data;
        this.cache = { ...DEFAULT_PROGRESS, ...progress };
        setLocal(this.cache);
        window.dispatchEvent(new CustomEvent("moneymunchersync", { detail: this.cache }));
      });
    } catch (e) {
      console.warn("Cloud init failed; running offline.", e);
    }
  }

  _cloudPush() {
    this.backend?.push(this.cache)
      .then(ok => { if (ok) localStorage.setItem(SYNC_FLAG, "false"); })
      .catch(() => {/* leave flag=true for retry later */});
  }
}

/* -----------------------------------------------------------
   6. LEGACY DROP-IN HELPERS (if you don't want the class yet)
   ----------------------------------------------------------- */
export function saveProgress(progress) { setLocal(progress); }
export function loadProgress()         { return getLocal(); }

// Default export for convenience
export default MoneyMuncherProgress;
