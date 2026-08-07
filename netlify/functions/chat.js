const DEFAULT_PROJECT_ENDPOINT = "https://ozankosulgan-2014-resource.services.ai.azure.com/api/projects/ozankosulgan-2014";
const DEFAULT_HOSTED_AGENT_NAME = "moneymuncher-helpdesk";
const MAX_MESSAGE_LENGTH = 700;

let cachedToken = null;

const headers = {
  "Content-Type": "application/json",
  "Cache-Control": "no-store"
};

function response(statusCode, payload) {
  return { statusCode, headers, body: JSON.stringify(payload) };
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

function cleanResponseId(value) {
  const text = String(value || "").trim();
  return /^resp_[A-Za-z0-9_-]{8,160}$/.test(text) ? text : "";
}

function projectEndpoint() {
  return pickEnv([
    "AZURE_AI_FOUNDRY_PROJECT_ENDPOINT",
    "AZURE_FOUNDRY_PROJECT_ENDPOINT",
    "FOUNDRY_PROJECT_ENDPOINT",
    "AZURE_AI_PROJECT_ENDPOINT",
    "PROJECT_ENDPOINT"
  ], DEFAULT_PROJECT_ENDPOINT).replace(/\/+$/, "");
}

function hostedAgentName() {
  return pickEnv([
    "AZURE_AI_FOUNDRY_HOSTED_AGENT_NAME",
    "AZURE_FOUNDRY_HOSTED_AGENT_NAME",
    "FOUNDRY_HOSTED_AGENT_NAME",
    "AZURE_AI_FOUNDRY_AGENT_NAME",
    "AZURE_FOUNDRY_AGENT_NAME",
    "FOUNDRY_AGENT_ID"
  ], DEFAULT_HOSTED_AGENT_NAME);
}

function responsesEndpoint() {
  const configured = pickEnv([
    "AZURE_AI_FOUNDRY_RESPONSES_ENDPOINT",
    "AZURE_FOUNDRY_RESPONSES_ENDPOINT",
    "FOUNDRY_RESPONSES_ENDPOINT"
  ]);
  return (configured || projectEndpoint() + "/agents/" + encodeURIComponent(hostedAgentName()) + "/endpoint/protocols/openai/responses").replace(/\/+$/, "");
}

function endpointUrl() {
  const endpoint = responsesEndpoint();
  const separator = endpoint.includes("?") ? "&" : "?";
  const version = pickEnv(["AZURE_AI_FOUNDRY_API_VERSION", "AZURE_FOUNDRY_API_VERSION", "API_VERSION"], "v1");
  return endpoint + separator + "api-version=" + encodeURIComponent(version);
}

async function authHeaders() {
  const tenantId = pickEnv(["AZURE_TENANT_ID", "AZURE_AI_TENANT_ID"]);
  const clientId = pickEnv(["AZURE_CLIENT_ID", "AZURE_AI_CLIENT_ID"]);
  const clientSecret = pickEnv(["AZURE_CLIENT_SECRET", "AZURE_AI_CLIENT_SECRET"]);

  if (tenantId && clientId && clientSecret) {
    const now = Math.floor(Date.now() / 1000);
    if (cachedToken && cachedToken.expiresAt - 120 > now) {
      return { Authorization: "Bearer " + cachedToken.accessToken };
    }

    const tokenResponse = await fetch(
      "https://login.microsoftonline.com/" + encodeURIComponent(tenantId) + "/oauth2/v2.0/token",
      {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          client_id: clientId,
          client_secret: clientSecret,
          grant_type: "client_credentials",
          scope: "https://ai.azure.com/.default"
        })
      }
    );
    const tokenBody = await tokenResponse.json().catch(() => ({}));
    if (!tokenResponse.ok || !tokenBody.access_token) throw new Error("Azure token request failed");

    cachedToken = {
      accessToken: tokenBody.access_token,
      expiresAt: now + Number(tokenBody.expires_in || 3600)
    };
    return { Authorization: "Bearer " + cachedToken.accessToken };
  }

  const staticToken = pickEnv(["AZURE_AI_FOUNDRY_AUTH_TOKEN", "AZURE_AI_AUTH_TOKEN", "FOUNDRY_ACCESS_TOKEN", "AGENT_TOKEN"]);
  if (staticToken) {
    return { Authorization: staticToken.startsWith("Bearer ") ? staticToken : "Bearer " + staticToken };
  }

  const apiKey = pickEnv(["AZURE_AI_FOUNDRY_API_KEY", "AZURE_FOUNDRY_API_KEY", "AZURE_AI_API_KEY", "FOUNDRY_API_KEY"]);
  return apiKey ? { "api-key": apiKey } : null;
}

function instructions(page) {
  const configured = pickEnv(["AZURE_AI_FOUNDRY_ADDITIONAL_INSTRUCTIONS", "DINO_CHAT_ADDITIONAL_INSTRUCTIONS"]);
  const pageHint = page?.path ? "The visitor is on " + String(page.path).slice(0, 80) + ". " : "";
  const guardrails = "Reply as Dino Munch, a warm family money-learning guide for MoneyMuncher. Keep replies short, practical, and age-appropriate. Do not ask for full names, addresses, phone numbers, school details, passwords, payment cards, or bank details. Encourage kids to involve a parent or teacher for real money decisions. Avoid personalized financial advice.";
  return pageHint + (configured || guardrails);
}

function responseText(payload) {
  if (typeof payload.output_text === "string" && payload.output_text.trim()) return payload.output_text.trim();

  const parts = [];
  for (const item of Array.isArray(payload.output) ? payload.output : []) {
    for (const part of Array.isArray(item?.content) ? item.content : []) {
      if (typeof part?.text === "string") parts.push(part.text);
      else if (typeof part?.text?.value === "string") parts.push(part.text.value);
      else if (typeof part?.value === "string") parts.push(part.value);
    }
  }
  return parts.join("\n").trim();
}

async function createResponse(message, previousResponseId, page) {
  const auth = await authHeaders();
  if (!auth) throw new Error("Azure Foundry authentication is not configured");

  const payload = {
    input: message,
    stream: false
  };
  if (previousResponseId) payload.previous_response_id = previousResponseId;

  const result = await fetch(endpointUrl(), {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      "Foundry-Features": "HostedAgents=V1Preview",
      ...auth
    },
    body: JSON.stringify(payload)
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
  if (!result.ok) {
    const detail = body.error?.message || body.message || body.detail || result.statusText;
    throw new Error("Foundry response failed (" + result.status + "): " + detail);
  }
  return body;
}

exports.handler = async (event) => {
  if (event.httpMethod !== "POST") return response(405, { error: "Method not allowed" });

  try {
    const body = JSON.parse(event.body || "{}");
    const message = cleanMessage(body.message);
    if (!message) return response(400, { error: "Message is required" });

    const foundryResponse = await createResponse(message, cleanResponseId(body.threadId), body.page || {});
    const reply = responseText(foundryResponse);
    if (!reply) throw new Error("Foundry returned no assistant text");

    return response(200, {
      reply,
      threadId: cleanResponseId(foundryResponse.id)
    });
  } catch (error) {
    console.error("Dino chat failed", error);
    return response(502, { error: "Dino chat is unavailable right now. Please try again soon." });
  }
};
