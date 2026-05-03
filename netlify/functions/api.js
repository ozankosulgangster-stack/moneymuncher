const crypto = require("node:crypto");
const { getStore } = require("@netlify/blobs");

const defaultProgress = () => ({ unlockedLevel: 0, completedLevels: [] });
const sanitize = (value) => String(value || "").trim().slice(0, 80);
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
  return { id: user.id, name: user.name, role: user.role, createdAt: user.createdAt, updatedAt: user.updatedAt };
}

exports.handler = async (event) => {
  try {
    const method = event.httpMethod;
    const path = event.queryStringParameters?.path || "";

    if (method === "POST" && path === "login") {
      const body = JSON.parse(event.body || "{}");
      const name = sanitize(body.name);
      const role = ["Kid", "Parent", "Teacher"].includes(body.role) ? body.role : "Kid";
      if (!name) return response(400, { error: "Name is required" });

      const { store, users } = await readUsers();
      const key = `${name.toLowerCase()}::${role.toLowerCase()}`;
      let user = users.find((item) => item.key === key);
      const now = new Date().toISOString();
      if (!user) {
        user = { id: crypto.randomUUID(), key, name, role, progress: defaultProgress(), createdAt: now, updatedAt: now };
        users.push(user);
      } else {
        user.name = name;
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
        unlockedLevel: Math.max(0, Math.min(4, Number(incoming.unlockedLevel) || 0)),
        completedLevels: Array.from(new Set((incoming.completedLevels || []).map(Number).filter((n) => n >= 0 && n <= 4)))
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

