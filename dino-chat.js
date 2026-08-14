(function () {
  if (window.MoneyMuncherDinoChatLoaded) return;
  window.MoneyMuncherDinoChatLoaded = true;

  const endpoint = "/.netlify/functions/chat";
  const storageKey = "moneymuncher.dino.threadId";
  const maxMessageLength = 700;

  let threadId = readThreadId();
  let sending = false;

  const launcher = document.createElement("button");
  launcher.className = "dino-chat-launcher";
  launcher.type = "button";
  launcher.setAttribute("aria-label", "Open Dino Munch chat");
  launcher.setAttribute("aria-expanded", "false");
  launcher.setAttribute("aria-controls", "dinoChatPanel");
  launcher.innerHTML = dinoFaceMarkup() + '<span class="dino-chat-ping" aria-hidden="true"></span>';

  const panel = document.createElement("section");
  panel.className = "dino-chat-panel";
  panel.id = "dinoChatPanel";
  panel.setAttribute("role", "dialog");
  panel.setAttribute("aria-label", "Ask Dino Munch");
  panel.innerHTML = `
    <header class="dino-chat-header">
      <div class="dino-chat-avatar" aria-hidden="true">${dinoFaceMarkup()}</div>
      <div class="dino-chat-title">
        <h2>Ask Dino Munch</h2>
        <p>Family money guide is online</p>
      </div>
      <div class="dino-chat-header-actions">
        <button class="dino-chat-icon-button" id="dinoChatNew" type="button" title="Start a new chat" aria-label="Start a new chat">New</button>
        <button class="dino-chat-icon-button" id="dinoChatClose" type="button" title="Close chat" aria-label="Close chat">x</button>
      </div>
    </header>
    <div class="dino-chat-messages" id="dinoChatMessages" aria-live="polite"></div>
    <div class="dino-chat-suggestions" id="dinoChatSuggestions"></div>
    <p class="dino-chat-privacy">Family note: Dino is for learning, not private info. Please do not share full names, addresses, passwords, card numbers, or school details.</p>
    <form class="dino-chat-form" id="dinoChatForm">
      <label class="dino-chat-sr-only" for="dinoChatInput">Ask Dino a question</label>
      <input class="dino-chat-input" id="dinoChatInput" type="text" maxlength="${maxMessageLength}" autocomplete="off" placeholder="Ask about saving, spending, or allowance">
      <button class="dino-chat-send" id="dinoChatSend" type="submit" aria-label="Send message">$</button>
    </form>
  `;

  document.body.appendChild(launcher);
  document.body.appendChild(panel);

  const closeButton = panel.querySelector("#dinoChatClose");
  const newButton = panel.querySelector("#dinoChatNew");
  const messagesEl = panel.querySelector("#dinoChatMessages");
  const suggestionsEl = panel.querySelector("#dinoChatSuggestions");
  const form = panel.querySelector("#dinoChatForm");
  const input = panel.querySelector("#dinoChatInput");
  const sendButton = panel.querySelector("#dinoChatSend");

  resetMessages();
  renderSuggestions();

  launcher.addEventListener("click", openChat);
  document.querySelectorAll("[data-open-dino-chat]").forEach((button) => {
    button.addEventListener("click", openChat);
  });
  closeButton.addEventListener("click", closeChat);
  newButton.addEventListener("click", startNewChat);
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    sendMessage(input.value);
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && panel.classList.contains("open")) closeChat();
  });

  function dinoFaceMarkup() {
    return '<span class="dino-chat-dino-face"><span class="dino-chat-eye left"></span><span class="dino-chat-eye right"></span><span class="dino-chat-smile"></span></span>';
  }

  function openChat() {
    panel.classList.add("open");
    launcher.setAttribute("aria-expanded", "true");
    window.setTimeout(() => input.focus(), 80);
  }

  function closeChat() {
    panel.classList.remove("open");
    launcher.setAttribute("aria-expanded", "false");
    launcher.focus();
  }

  function startNewChat() {
    threadId = null;
    writeThreadId(null);
    resetMessages();
    renderSuggestions();
    input.value = "";
    input.focus();
  }

  function resetMessages() {
    messagesEl.innerHTML = "";
    addMessage(
      "Hi, I'm Dino Munch. Ask me a family money question about saving, spending, allowance, needs vs wants, or Market Lab.",
      "bot"
    );
  }

  function renderSuggestions() {
    suggestionsEl.innerHTML = "";
    pageSuggestions().forEach((suggestion) => {
      const button = document.createElement("button");
      button.className = "dino-chat-chip";
      button.type = "button";
      button.textContent = suggestion.label;
      button.addEventListener("click", () => sendMessage(suggestion.question));
      suggestionsEl.appendChild(button);
    });
  }

  function pageSuggestions() {
    const path = window.location.pathname.toLowerCase();
    if (path.includes("scam-smart")) {
      return [
        { label: "What should I say?", question: "Give me the short Stop, Check, Tell script for a suspicious money DM." },
        { label: "Spot a scam clue", question: "What are three simple clues that a money DM could be a scam?" },
        { label: "Tell a grown-up", question: "Help me practice telling a trusted adult about a suspicious message." }
      ];
    }
    if (path.includes("classroom-market")) {
      return [
        { label: "Best value?", question: "How can a class compare price, quality, and need before choosing?" },
        { label: "Need vs want", question: "Can you explain needs versus wants with classroom supplies?" },
        { label: "Team budget", question: "How should a team decide what to buy with limited class coins?" }
      ];
    }
    if (path.includes("market-lab")) {
      return [
        { label: "What is an ETF?", question: "Explain an ETF to a kid using virtual coins." },
        { label: "Why prices move", question: "Why do stock prices go up and down?" },
        { label: "Risk check", question: "How can a family talk about investment risk safely?" }
      ];
    }
    if (path.includes("rewards")) {
      return [
        { label: "Pick a badge", question: "Which reward badge should I save for first?" },
        { label: "Save or spend?", question: "Should I spend my practice coins now or save them?" },
        { label: "Goal idea", question: "Help me make a small saving goal." }
      ];
    }
    return [
      { label: "Start saving", question: "How do I start a savings jar?" },
      { label: "Allowance idea", question: "What is a good chore plan for earning allowance?" },
      { label: "Interest", question: "What does interest mean for kids?" }
    ];
  }

  function addMessage(text, sender) {
    const row = document.createElement("div");
    row.className = "dino-chat-row " + sender;

    const avatar = document.createElement("div");
    avatar.className = "dino-chat-mini-avatar";
    avatar.setAttribute("aria-hidden", "true");
    avatar.innerHTML = sender === "bot" ? dinoFaceMarkup() : "You";

    const bubble = document.createElement("div");
    bubble.className = "dino-chat-bubble";
    bubble.textContent = text;

    row.appendChild(avatar);
    row.appendChild(bubble);
    messagesEl.appendChild(row);
    messagesEl.scrollTop = messagesEl.scrollHeight;
  }

  function showTyping() {
    const row = document.createElement("div");
    row.className = "dino-chat-row bot";
    row.id = "dinoChatTyping";
    row.innerHTML = `
      <div class="dino-chat-mini-avatar" aria-hidden="true">${dinoFaceMarkup()}</div>
      <div class="dino-chat-loader" aria-label="Dino is thinking"><span></span><span></span><span></span></div>
    `;
    messagesEl.appendChild(row);
    messagesEl.scrollTop = messagesEl.scrollHeight;
  }

  function hideTyping() {
    const row = panel.querySelector("#dinoChatTyping");
    if (row) row.remove();
  }

  async function sendMessage(rawText) {
    const text = String(rawText || "").trim().replace(/\s+/g, " ").slice(0, maxMessageLength);
    if (!text || sending) return;

    sending = true;
    input.value = "";
    sendButton.disabled = true;
    suggestionsEl.hidden = true;
    addMessage(text, "user");
    showTyping();

    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          message: text,
          threadId,
          page: {
            title: document.title,
            path: window.location.pathname
          }
        })
      });
      const data = await readJson(response);
      if (!response.ok) throw new Error(data.error || "Dino chat request failed");

      if (data.threadId) {
        threadId = data.threadId;
        writeThreadId(threadId);
      }

      hideTyping();
      addMessage(data.reply || localTip(text), "bot");
    } catch (error) {
      hideTyping();
      addMessage(localTip(text), "bot");
    } finally {
      sending = false;
      sendButton.disabled = false;
      input.focus();
    }
  }

  async function readJson(response) {
    try {
      return await response.json();
    } catch (error) {
      return {};
    }
  }

  function localTip(text) {
    const lower = text.toLowerCase();
    let tip = "Try naming the choice, the cost, and what you might want later. That makes the money choice easier to see.";
    if (lower.includes("interest")) {
      tip = "Interest is extra money earned or paid over time. A savings account may pay you a little interest, while debt can charge you interest.";
    } else if (lower.includes("allowance") || lower.includes("chore")) {
      tip = "A simple allowance plan is Spend, Save, and Share. Pick one job, one payday, and one small saving goal.";
    } else if (lower.includes("save") || lower.includes("saving") || lower.includes("jar")) {
      tip = "Start with one clear goal, like a book or game. Put coins in a jar each week and mark progress so your brain can see the win.";
    } else if (lower.includes("want") || lower.includes("need")) {
      tip = "A need helps you stay healthy, safe, or ready for school. A want can still be fun, but it should wait its turn in the budget.";
    } else if (lower.includes("stock") || lower.includes("etf") || lower.includes("market")) {
      tip = "Market Lab uses practice coins only. A family can compare what a company does, why people buy it, and what could go wrong.";
    }
    return "I am having trouble reaching the live family agent right now, but here is a Dino tip: " + tip;
  }

  function readThreadId() {
    try {
      return window.localStorage.getItem(storageKey);
    } catch (error) {
      return null;
    }
  }

  function writeThreadId(value) {
    try {
      if (value) window.localStorage.setItem(storageKey, value);
      else window.localStorage.removeItem(storageKey);
    } catch (error) {
      // Local storage can be unavailable in private or restricted browsers.
    }
  }
})();
