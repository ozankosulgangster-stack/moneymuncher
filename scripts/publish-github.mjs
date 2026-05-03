import fs from "node:fs/promises";
import path from "node:path";

const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
const owner = process.env.GITHUB_OWNER;
const repo = process.env.GITHUB_REPO || "moneymuncher";
const branch = process.env.GITHUB_BRANCH || "main";

if (!token) throw new Error("Missing GITHUB_TOKEN or GH_TOKEN");
if (!owner) throw new Error("Missing GITHUB_OWNER");

const root = process.cwd();
const ignore = new Set(["node_modules", "data", ".netlify", ".git"]);

async function github(pathname, options = {}) {
  const res = await fetch(`https://api.github.com${pathname}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
      ...(options.headers || {})
    }
  });
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}: ${await res.text()}`);
  return res.status === 204 ? null : res.json();
}

async function listFiles(dir = root) {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    if (ignore.has(entry.name)) continue;
    const full = path.join(dir, entry.name);
    const rel = path.relative(root, full).replaceAll(path.sep, "/");
    if (entry.isDirectory()) files.push(...await listFiles(full));
    else files.push(rel);
  }
  return files;
}

async function ensureRepo() {
  try {
    return await github(`/repos/${owner}/${repo}`);
  } catch (error) {
    if (!String(error.message).startsWith("404")) throw error;
    return github("/user/repos", {
      method: "POST",
      body: JSON.stringify({ name: repo, private: false, description: "MoneyMuncher financial education game prototype" })
    });
  }
}

await ensureRepo();
const files = await listFiles();
for (const file of files) {
  const content = await fs.readFile(path.join(root, file), "base64");
  let sha;
  try {
    const existing = await github(`/repos/${owner}/${repo}/contents/${encodeURIComponent(file).replaceAll("%2F", "/")}?ref=${branch}`);
    sha = existing.sha;
  } catch (error) {
    if (!String(error.message).startsWith("404")) throw error;
  }
  await github(`/repos/${owner}/${repo}/contents/${encodeURIComponent(file).replaceAll("%2F", "/")}`, {
    method: "PUT",
    body: JSON.stringify({ message: `Publish ${file}`, content, branch, sha })
  });
  console.log(`uploaded ${file}`);
}
console.log(`Published GitHub repo: https://github.com/${owner}/${repo}`);
