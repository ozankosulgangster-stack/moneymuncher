const DEFAULT_PROJECT_ENDPOINT = "https://ozankosulgan-2014-resource.services.ai.azure.com/api/projects/ozankosulgan-2014";
const DEFAULT_API_VERSION = "v1";
const CLASSIC_API_VERSION = "2025-05-01";
const MAX_MESSAGE_LENGTH = 700;
const POLL_DELAY_MS = 900;
const MAX_POLLS = 24;

let cachedToken = null;
let resolvedApiVersion = null;

const headers = {
  "Content-Type": "application/json",
  "Cache-Control": "no-store"
};

function response(statusCode, payload) {
  return {
    statusCode,
    headers,
    body: JSON.stringify(payload)
  };
}

function pickEnv(names, fallback = "") {
  for (const name of names) {
    const value = process.env[name];
    if (value && String(value).trim()) return String(value).trim();
  }
  return fallback;
}

function cleanMessage(value) {
  return String(value || "").replace(/\s+/g, " ").trim().slice(0, MAX_MESSAGE_LENGTH);
}

function cleanThreadId(value) {
  const text = String(value || "").trim();
  return /^[A-Za-z0-9_-]{8,160}$/.test(text) ? text : "";
}

function safeText(value, maxLength = 120) {
  return String(value || "").replace(/\s+/g, " ").trim().slice(0, maxLength);
}

function configuredApiVersion() {
  return pickEnv(["AZURE_AI_FOUNDRY_API_VERSION", "AZURE_FOUNDRY_API_VERSION", "API_VERSION"]);
}

function apiVersions() {
  const configured = configuredApiVersion();
  if (configured) return [configured];
  return [DEFAULT_API_VERSION, CLASSIC_API_VERSION];
}

function endpointUrl(path, version) {
  const endpoint = pickEnv(
    ["AZURE_AI_FOUNDRY_PROJECT_ENDPOINT", "AZURE_FOUNDRY_PROJECT_ENDPOINT", "AZURE_AI_PROJECT_ENDPOINT", "PROJECT_ENDPOINT"],
    DEFAULT_PROJECT_ENDPOINT
  ).replace(/\/+$/, "");
  const separator = path.includes("?") ? "&" : "?";
  return `${endpoint}${path}${separator}api-version=${encodeURIComponent(version)}`;
}

async function authHeaders() {
  const apiKey = pickEnv(["AZURE_AI_FOUNDRY_API_KEY", "AZURE_FOUNDRY_API_KEY", "AZURE_AI_API_KEY", "FOUNDRY_API_KEY"]);
  if (apiKey) return { "api-key": apiKey };

  const staticToken = pickEnv(["AZURE_AI_FOUNDRY_AUTH_TOKEN", "AZURE_AI_AUTH_TOKEN", "FOUNDRY_ACCESS_TOKEN", "AGENT_TOKEN"]);
  if (staticToken) {
    return { Authorization: staticToken.startsWith("Bearer ") ? staticToken : `Bearer ${staticToken}` };
  }

  const tenantId = pickEnv(["AZURE_TENANT_ID", "AZURE_AI_TENANT_ID"]);
  const clientId = pickEnv(["AZURE_CLIENT_ID", "AZURE_AI_CLIENT_ID"]);
  const clientSecret = pickEnv(["AZURE_CLIENT_SECRET", "AZURE_AI_CLIENT_SECRET"]);
  if (!tenantId || !clientId || !clientSecret) return null;

  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt - 120 > now) {
    return { Authorization: `Bearer ${cachedToken.accessToken}` };
  }

  const body = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    grant_type: "client_credentials",
    scope: "https://ai.azure.com/.default"
  });

  const tokenResponse = await fetch(`https://login.microsoftonline.com/${encodeURIComponent(tenantId)}/oauth2/v2.0/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body
  });

  const tokenBody = await tokenResponse.json().catch(() => ({}));
  if (!tokenResponse.ok || !tokenBody.access_token) {
    throw new Error("Azure token request failed");
  }

  cachedToken = {
    accessToken: tokenBody.access_token,
    expiresAt: now + Number(tokenBody.expires_in || 3600)
  };

  return { Authorization: `Bearer ${cachedToken.accessToken}` };
}

async function foundryRequest(path, options = {}) {
  const auth = await authHeaders();
  if (!auth) throw new Error("Azure Foundry authentication is not configured");

  const versions = resolvedApiVersion ? [resolvedApiVersion] : apiVersions();
  let lastError = null;

  for (const version of versions) {
    const result = await fetch(endpointUrl(path, version), {
      ...options,
      headers: {
        Accept: "application/json",
        ...auth,
        ...(options.body ? { "Content-Type": "application/json" } : {}),
        ...(options.headers || {})
      }
    });

    const text = await result.text();
    let body = {};
    if (text) {
      try {
        body = JSON.parse(text);
      } catch (error) {
        body = { raw: text };
      }
    }

    if (result.ok) {
      resolvedApiVersion = version;
      return body;
    }

    const detail = body.error?.message || body.message || body.detail || result.statusText;
    lastError = new Error(`Foundry request failed (${result.status}): ${detail}`);
    if (configuredApiVersion() || ![400, 404, 422].includes(result.status)) throw lastError;
  }

  throw lastError || new Error("Foundry request failed");
}

async function ensureThread(threadId) {
  if (threadId) return threadId;
  const thread = await foundryRequest("/threads", {
    method: "POST",
    body: JSON.stringify({})
  });
  if (!thread.id) throw new Error("Foundry did not return a thread id");
  return thread.id;
}

function assistantId() {
  return pickEnv(["AZURE_AI_FOUNDRY_AGENT_ID", "AZURE_FOUNDRY_AGENT_ID", "AZURE_AI_AGENT_ID", "AGENT_ID", "ASSISTANT_ID"]);
}

function additionalInstructions(page) {
  const configured = pickEnv(["AZURE_AI_FOUNDRY_ADDITIONAL_INSTRUCTIONS", "DINO_CHAT_ADDITIONAL_INSTRUCTIONS"]);
  const pageHint = page?.path ? `The visitor is on ${safeText(page.path, 80)} (${safeText(page.title, 100)}). ` : "";
  const guardrails = "Reply as Dino Munch, a warm family money-learning guide for MoneyMuncher. Keep replies short, practical, and age-appropriate. Do not ask for full names, addresses, phone numbers, school details, passwords, payment cards, or bank details. Encourage kids to involve a parent or teacher for real money decisions. Avoid personalized financial advice.";
  return `${pageHint}${configured || guardrails}`;
}

async function runAgent(threadId, message, page) {
  const agentId = assistantId();
  if (!agentId) throw new Error("Azure Foundry agent id is not configured");

  await foundryRequest(`/threads/${encodeURIComponent(threadId)}/messages`, {
    method: "POST",
    body: JSON.stringify({
      role: "user",
      content: message
    })
  });

  const run = await foundryRequest(`/threads/${encodeURIComponent(threadId)}/runs`, {
    method: "POST",
    body: JSON.stringify({
      assistant_id: agentId,
      additional_instructions: additionalInstructions(page)
    })
  });
  if (!run.id) throw new Error("Foundry did not return a run id");

  let currentRun = run;
  for (let index = 0; index < MAX_POLLS; index += 1) {
    const status = String(currentRun.status || "").toLowerCase();
    if (["completed", "failed", "cancelled", "canceled", "expired"].includes(status)) break;
    if (status === "requires_action") {
      throw new Error("The Foundry agent requires tool action that this chat proxy cannot complete");
    }
    await delay(POLL_DELAY_MS);
    currentRun = await foundryRequest(`/threads/${encodeURIComponent(threadId)}/runs/${encodeURIComponent(run.id)}`);
  }

  const finalStatus = String(currentRun.status || "").toLowerCase();
  if (finalStatus !== "completed") {
    const errorMessage = currentRun.last_error?.message || `Agent run ended with status ${finalStatus || "unknown"}`;
    throw new Error(errorMessage);
  }

  const messages = await foundryRequest(`/threads/${encodeURIComponent(threadId)}/messages?order=desc&limit=12`);
  return extractAssistantReply(messages, run.id);
}

function extractAssistantReply(payload, runId) {
  const messages = Array.isArray(payload.data)
    ? payload.data
    : Array.isArray(payload.value)
      ? payload.value
      : Array.isArray(payload.messages)
        ? payload.messages
        : [];

  const sorted = messages.slice().sort((left, right) => Number(right.created_at || right.createdAt || 0) - Number(left.created_at || left.createdAt || 0));
  const exact = sorted.find((message) => message.role === "assistant" && (!runId || message.run_id === runId || message.runId === runId));
  const assistant = exact || sorted.find((message) => message.role === "assistant");
  const text = messageText(assistant);
  if (!text) throw new Error("Foundry returned no assistant text");
  return text;
}

function messageText(message) {
  if (!message) return "";
  if (typeof message.content === "string") return message.content.trim();
  if (Array.isArray(message.text_messages) && message.text_messages.length) {
    return message.text_messages.map((item) => item.text?.value || item.text || "").filter(Boolean).join("\n").trim();
  }
  if (!Array.isArray(message.content)) return "";

  return message.content.map((part) => {
    if (typeof part === "string") return part;
    if (typeof part.text === "string") return part.text;
    if (part.text?.value) return part.text.value;
    if (part.value) return part.value;
    return "";
  }).filter(Boolean).join("\n").trim();
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

exports.handler = async (event) => {
  if (event.httpMethod !== "POST") {
    return response(405, { error: "Method not allowed" });
  }

  try {
    const body = JSON.parse(event.body || "{}");
    const message = cleanMessage(body.message);
    if (!message) return response(400, { error: "Message is required" });

    const threadId = await ensureThread(cleanThreadId(body.threadId));
    const reply = await runAgent(threadId, message, body.page || {});
    return response(200, { reply, threadId });
  } catch (error) {
    console.error("Dino chat failed", error);
    return response(502, {
      error: "Dino chat is unavailable right now. Please try again soon."
    });
  }
};
