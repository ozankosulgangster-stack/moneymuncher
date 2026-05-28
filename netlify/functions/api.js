const crypto = require("node:crypto");
const { getStore } = require("@netlify/blobs");

const defaultProgress = () => ({
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
  transactions: [],
  lifetimeCoinsEarned: 0,
  lifetimeCoinsSpent: 0
});
const sanitize = (value) => String(value || "").trim().slice(0, 80);
const sanitizeEmail = (value) => String(value || "").trim().toLowerCase().slice(0, 160);
const roles = ["Kid Explorer", "Parent Guide", "Teacher Captain", "Family Team", "Kid", "Parent", "Teacher"];
const normalizeRole = (role) => ({
  Kid: "Kid Explorer",
  Parent: "Parent Guide",
  Teacher: "Teacher Captain"
}[role] || role);
const headers = { "Content-Type": "application/json" };

function response(statusCode, payload) {
  return { statusCode, headers, body: JSON.stringify(payload) };
}

async function readUsers() {
  const store = getStore("moneymuncher-users");
  const users = await store.get("users", { type: "json" });
  return { store, users: Array.isArray(users) ? users : [] };
}

function safeUser(user) {
  return { id: user.id, email: user.email || "", name: user.name, role: user.role, createdAt: user.createdAt, updatedAt: user.updatedAt };
}

exports.handler = async (event) => {
  try {
    const method = event.httpMethod;
    const path = event.queryStringParameters?.path || "";

    if (method === "POST" && path === "login") {
      const body = JSON.parse(event.body || "{}");
      const name = sanitize(body.name);
      const email = sanitizeEmail(body.email);
      const role = roles.includes(body.role) ? normalizeRole(body.role) : "Kid Explorer";
      if (!name && !email) return response(400, { error: "Name or email is required" });

      const { store, users } = await readUsers();
      const key = email || `${name.toLowerCase()}::${role.toLowerCase()}`;
      let user = users.find((item) => item.key === key);
      const now = new Date().toISOString();
      if (!user) {
        user = { id: crypto.randomUUID(), key, email, name: name || email.split("@")[0], role, progress: defaultProgress(), createdAt: now, updatedAt: now };
        users.push(user);
      } else {
        user.email = email || user.email || "";
        user.name = name || user.name;
        user.role = role;
        user.updatedAt = now;
      }
      await store.setJSON("users", users);
      return response(200, { user: safeUser(user), progress: user.progress || defaultProgress() });
    }

    const userMatch = path.match(/^users\/([^/]+)$/);
    if (method === "GET" && userMatch) {
      const { users } = await readUsers();
      const user = users.find((item) => item.id === userMatch[1]);
      if (!user) return response(404, { error: "User not found" });
      return response(200, { user: safeUser(user), progress: user.progress || defaultProgress() });
    }

    const progressMatch = path.match(/^users\/([^/]+)\/progress$/);
    if (method === "PUT" && progressMatch) {
      const body = JSON.parse(event.body || "{}");
      const incoming = body.progress || {};
      const { store, users } = await readUsers();
      const user = users.find((item) => item.id === progressMatch[1]);
      if (!user) return response(404, { error: "User not found" });
      user.progress = {
        ...defaultProgress(),
        ...user.progress,
        coins: Math.max(0, Number(incoming.coins) || 0),
        saved: Math.max(0, Number(incoming.saved) || 0),
        joy: Math.max(0, Number(incoming.joy) || 0),
        wisdom: Math.max(0, Number(incoming.wisdom) || 0),
        level: Math.max(1, Number(incoming.level) || 1),
        badges: Array.from(new Set(incoming.badges || [])),
        currentLevel: Math.max(0, Math.min(7, Number(incoming.currentLevel) || 0)),
        unlockedLevel: Math.max(0, Math.min(7, Number(incoming.unlockedLevel) || 0)),
        completedLevels: Array.from(new Set((incoming.completedLevels || []).map(Number).filter((n) => n >= 0 && n <= 7))),
        completedLessons: Array.from(new Set(incoming.completedLessons || [])),
        shopBadges: Array.from(new Set(incoming.shopBadges || [])),
        transactions: Array.isArray(incoming.transactions) ? incoming.transactions.slice(-80) : [],
        lifetimeCoinsEarned: Math.max(0, Number(incoming.lifetimeCoinsEarned) || 0),
        lifetimeCoinsSpent: Math.max(0, Number(incoming.lifetimeCoinsSpent) || 0)
      };
      user.updatedAt = new Date().toISOString();
      await store.setJSON("users", users);
      return response(200, { user: safeUser(user), progress: user.progress });
    }

    return response(404, { error: "Not found" });
  } catch (error) {
    return response(500, { error: "Server error", detail: error.message });
  }
};

