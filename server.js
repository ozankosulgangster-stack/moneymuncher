const http = require("node:http");
const fs = require("node:fs/promises");
const path = require("node:path");
const crypto = require("node:crypto");

const root = __dirname;
const dataDir = path.join(root, "data");
const dbPath = path.join(dataDir, "db.json");
const port = process.env.PORT || 4173;

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
  completedLessons: []
});
const sanitize = (value) => String(value || "").trim().slice(0, 80);
const sanitizeEmail = (value) => String(value || "").trim().toLowerCase().slice(0, 160);

async function readDb() {
  await fs.mkdir(dataDir, { recursive: true });
  try {
    return JSON.parse(await fs.readFile(dbPath, "utf8"));
  } catch {
    return { users: [] };
  }
}

async function writeDb(db) {
  await fs.mkdir(dataDir, { recursive: true });
  await fs.writeFile(dbPath, JSON.stringify(db, null, 2));
}

async function readBody(req) {
  let body = "";
  for await (const chunk of req) body += chunk;
  return body ? JSON.parse(body) : {};
}

function sendJson(res, status, payload) {
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(payload));
}

function safeUser(user) {
  return { id: user.id, email: user.email || "", name: user.name, role: user.role, createdAt: user.createdAt, updatedAt: user.updatedAt };
}

async function handleApi(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (req.method === "POST" && url.pathname === "/api/login") {
    const body = await readBody(req);
    const name = sanitize(body.name);
    const email = sanitizeEmail(body.email);
    const role = ["Kid", "Parent", "Teacher"].includes(body.role) ? body.role : "Kid";
    if (!name && !email) return sendJson(res, 400, { error: "Name or email is required" });

    const db = await readDb();
    const key = email || `${name.toLowerCase()}::${role.toLowerCase()}`;
    let user = db.users.find((item) => item.key === key);
    const now = new Date().toISOString();
    if (!user) {
      user = { id: crypto.randomUUID(), key, email, name: name || email.split("@")[0], role, progress: defaultProgress(), createdAt: now, updatedAt: now };
      db.users.push(user);
    } else {
      user.email = email || user.email || "";
      user.name = name || user.name;
      user.role = role;
      user.updatedAt = now;
    }
    await writeDb(db);
    return sendJson(res, 200, { user: safeUser(user), progress: user.progress || defaultProgress() });
  }

  const userMatch = url.pathname.match(/^\/api\/users\/([^/]+)$/);
  if (req.method === "GET" && userMatch) {
    const db = await readDb();
    const user = db.users.find((item) => item.id === userMatch[1]);
    if (!user) return sendJson(res, 404, { error: "User not found" });
    return sendJson(res, 200, { user: safeUser(user), progress: user.progress || defaultProgress() });
  }

  const progressMatch = url.pathname.match(/^\/api\/users\/([^/]+)\/progress$/);
  if (req.method === "PUT" && progressMatch) {
    const body = await readBody(req);
    const incoming = body.progress || {};
    const db = await readDb();
    const user = db.users.find((item) => item.id === progressMatch[1]);
    if (!user) return sendJson(res, 404, { error: "User not found" });
    user.progress = {
      ...defaultProgress(),
      ...user.progress,
      coins: Math.max(0, Number(incoming.coins) || 0),
      saved: Math.max(0, Number(incoming.saved) || 0),
      joy: Math.max(0, Number(incoming.joy) || 0),
      wisdom: Math.max(0, Number(incoming.wisdom) || 0),
      level: Math.max(1, Number(incoming.level) || 1),
      badges: Array.from(new Set(incoming.badges || [])),
      currentLevel: Math.max(0, Math.min(4, Number(incoming.currentLevel) || 0)),
      unlockedLevel: Math.max(0, Math.min(4, Number(incoming.unlockedLevel) || 0)),
      completedLevels: Array.from(new Set((incoming.completedLevels || []).map(Number).filter((n) => n >= 0 && n <= 4))),
      completedLessons: Array.from(new Set(incoming.completedLessons || []))
    };
    user.updatedAt = new Date().toISOString();
    await writeDb(db);
    return sendJson(res, 200, { user: safeUser(user), progress: user.progress });
  }

  sendJson(res, 404, { error: "Not found" });
}

async function serveStatic(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const requested = url.pathname === "/" ? "/index.html" : decodeURIComponent(url.pathname);
  const filePath = path.normalize(path.join(root, requested));
  if (!filePath.startsWith(root)) {
    res.writeHead(403);
    return res.end("Forbidden");
  }
  try {
    const data = await fs.readFile(filePath);
    const ext = path.extname(filePath).toLowerCase();
    const types = { ".html": "text/html", ".css": "text/css", ".js": "text/javascript", ".json": "application/json" };
    res.writeHead(200, { "Content-Type": types[ext] || "application/octet-stream" });
    res.end(data);
  } catch {
    res.writeHead(404);
    res.end("Not found");
  }
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.url.startsWith("/api/")) return await handleApi(req, res);
    await serveStatic(req, res);
  } catch (error) {
    sendJson(res, 500, { error: "Server error", detail: error.message });
  }
});

server.listen(port, () => {
  console.log(`MoneyMuncher running at http://127.0.0.1:${port}`);
});
