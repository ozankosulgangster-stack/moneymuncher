(function () {
  const root = document.querySelector("#chorePlanner");
  if (!root || window.MoneyMuncherChorePlannerLoaded) return;
  window.MoneyMuncherChorePlannerLoaded = true;

  const storageKey = "moneymuncher.chorePlan.v1";
  const templates = {
    "little-helper": {
      split: { spend: 40, save: 50, give: 10 },
      chores: [
        chore("Make the bed", 2, "points"),
        chore("Put toys and books away", 3, "points"),
        chore("Help clear the table", 2, "points"),
        chore("Match clean socks", 3, "points")
      ]
    },
    "allowance-builder": {
      split: { spend: 40, save: 50, give: 10 },
      chores: [
        chore("Load or unload the dishwasher", 1.5, "dollars"),
        chore("Fold and put away laundry", 2, "dollars"),
        chore("Tidy the bedroom", 1.5, "dollars"),
        chore("Help with a family meal", 2, "dollars")
      ]
    },
    "school-week": {
      split: { spend: 30, save: 60, give: 10 },
      chores: [
        chore("Pack the school bag", 2, "points"),
        chore("Put lunch items by the sink", 1, "points"),
        chore("Finish the homework check", 3, "points"),
        chore("Prepare clothes for tomorrow", 2, "points")
      ]
    }
  };

  const elements = {
    list: root.querySelector("#choreList"),
    progressText: root.querySelector("#choreProgressText"),
    progressBar: root.querySelector("#choreProgressBar"),
    spend: root.querySelector("#choreSpend"),
    save: root.querySelector("#choreSave"),
    give: root.querySelector("#choreGive"),
    splitStatus: root.querySelector("#choreSplitStatus"),
    earned: root.querySelector("#choreEarned"),
    spendTotal: root.querySelector("#choreSpendTotal"),
    saveTotal: root.querySelector("#choreSaveTotal"),
    giveTotal: root.querySelector("#choreGiveTotal"),
    download: root.querySelector("#downloadChorePlanBtn")
  };

  let state = readState() || cloneTemplate("allowance-builder");
  normalizeState();
  bindEvents();
  render();

  function chore(title, value, kind) {
    return { id: makeId(), title, value, kind, complete: false };
  }

  function makeId() {
    if (window.crypto && typeof window.crypto.randomUUID === "function") return window.crypto.randomUUID();
    return "chore-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 9);
  }

  function cloneTemplate(name) {
    const template = templates[name];
    return {
      split: { ...template.split },
      chores: template.chores.map((item) => ({ ...item, id: makeId(), complete: false }))
    };
  }

  function normalizeState() {
    if (!state || typeof state !== "object") state = cloneTemplate("allowance-builder");
    if (!state.split) state.split = { spend: 40, save: 50, give: 10 };
    state.split.spend = clampNumber(state.split.spend, 0, 100, 40);
    state.split.save = clampNumber(state.split.save, 0, 100, 50);
    state.split.give = clampNumber(state.split.give, 0, 100, 10);
    state.chores = Array.isArray(state.chores) ? state.chores.slice(0, 50).map((item) => ({
      id: String(item.id || makeId()),
      title: String(item.title || "New chore").slice(0, 80),
      value: clampNumber(item.value, 0, 999, 0),
      kind: item.kind === "points" ? "points" : "dollars",
      complete: Boolean(item.complete)
    })) : [];
  }

  function clampNumber(value, min, max, fallback) {
    const number = Number(value);
    return Number.isFinite(number) ? Math.min(max, Math.max(min, number)) : fallback;
  }

  function bindEvents() {
    root.querySelectorAll("[data-chore-template]").forEach((button) => {
      button.addEventListener("click", () => loadTemplate(button.dataset.choreTemplate));
    });

    root.querySelector("#addChoreBtn").addEventListener("click", () => {
      state.chores.push(chore("New chore", 1, "points"));
      saveState();
      render();
      const lastTitle = elements.list.querySelector(".chore-row:last-child .chore-title");
      if (lastTitle) {
        lastTitle.focus();
        lastTitle.select();
      }
    });

    elements.list.addEventListener("click", (event) => {
      const row = event.target.closest("[data-chore-id]");
      if (!row) return;
      const item = findChore(row.dataset.choreId);
      if (!item) return;

      if (event.target.closest("[data-chore-toggle]")) {
        item.complete = !item.complete;
        saveState();
        render();
      }
      if (event.target.closest("[data-chore-remove]")) {
        state.chores = state.chores.filter((choreItem) => choreItem.id !== item.id);
        saveState();
        render();
      }
    });

    elements.list.addEventListener("input", (event) => {
      const row = event.target.closest("[data-chore-id]");
      if (!row) return;
      const item = findChore(row.dataset.choreId);
      if (!item) return;

      if (event.target.matches(".chore-title")) item.title = event.target.value.slice(0, 80);
      if (event.target.matches(".chore-value")) item.value = clampNumber(event.target.value, 0, 999, 0);
      saveState();
      renderSummary();
    });

    elements.list.addEventListener("change", (event) => {
      const row = event.target.closest("[data-chore-id]");
      if (!row) return;
      const item = findChore(row.dataset.choreId);
      if (!item) return;
      if (event.target.matches(".chore-kind")) item.kind = event.target.value === "points" ? "points" : "dollars";
      saveState();
      renderSummary();
    });

    [elements.spend, elements.save, elements.give].forEach((input) => {
      input.addEventListener("input", () => {
        state.split.spend = clampNumber(elements.spend.value, 0, 100, 0);
        state.split.save = clampNumber(elements.save.value, 0, 100, 0);
        state.split.give = clampNumber(elements.give.value, 0, 100, 0);
        saveState();
        renderSummary();
      });
    });

    elements.download.addEventListener("click", downloadCSV);
    root.querySelector("#printChorePlanBtn").addEventListener("click", () => window.print());
    root.querySelector("#resetChorePlanBtn").addEventListener("click", () => {
      if (state.chores.length && !window.confirm("Start over with a blank chore plan?")) return;
      state = { split: { spend: 40, save: 50, give: 10 }, chores: [] };
      saveState();
      render();
    });
  }

  function loadTemplate(name) {
    if (!templates[name]) return;
    if (state.chores.length && !window.confirm("Replace the current plan with this template?")) return;
    state = cloneTemplate(name);
    saveState();
    render();
  }

  function findChore(id) {
    return state.chores.find((item) => item.id === id);
  }

  function render() {
    elements.spend.value = state.split.spend;
    elements.save.value = state.split.save;
    elements.give.value = state.split.give;

    if (!state.chores.length) {
      elements.list.innerHTML = '<div class="chore-empty">Choose a starter template above or add your first chore. Your plan will save automatically on this device.</div>';
    } else {
      elements.list.innerHTML = state.chores.map((item) => `
        <div class="chore-row${item.complete ? " complete" : ""}" data-chore-id="${escapeHTML(item.id)}">
          <button class="chore-check" type="button" data-chore-toggle aria-label="${item.complete ? "Mark incomplete" : "Mark complete"}" aria-pressed="${item.complete}">${item.complete ? "✓" : ""}</button>
          <input class="chore-title" type="text" maxlength="80" value="${escapeHTML(item.title)}" aria-label="Chore name" />
          <input class="chore-value" type="number" min="0" max="999" step="0.5" value="${formatInputNumber(item.value)}" aria-label="Reward value" />
          <select class="chore-kind" aria-label="Reward type">
            <option value="dollars"${item.kind === "dollars" ? " selected" : ""}>Dollars</option>
            <option value="points"${item.kind === "points" ? " selected" : ""}>Points</option>
          </select>
          <button class="chore-remove" type="button" data-chore-remove aria-label="Remove ${escapeHTML(item.title)}">Remove</button>
        </div>
      `).join("");
    }
    renderSummary();
  }

  function renderSummary() {
    const completed = state.chores.filter((item) => item.complete);
    const dollars = completed.filter((item) => item.kind === "dollars").reduce((sum, item) => sum + item.value, 0);
    const points = completed.filter((item) => item.kind === "points").reduce((sum, item) => sum + item.value, 0);
    const percent = state.chores.length ? (completed.length / state.chores.length) * 100 : 0;
    const splitTotal = state.split.spend + state.split.save + state.split.give;
    const validSplit = Math.abs(splitTotal - 100) < 0.001;

    elements.progressText.textContent = completed.length + " of " + state.chores.length + " complete";
    elements.progressBar.style.width = percent + "%";
    elements.earned.textContent = money(dollars) + " + " + formatInputNumber(points) + " pts";
    elements.spendTotal.textContent = money(dollars * state.split.spend / 100);
    elements.saveTotal.textContent = money(dollars * state.split.save / 100);
    elements.giveTotal.textContent = money(dollars * state.split.give / 100);
    elements.splitStatus.textContent = validSplit
      ? "Perfect — your split adds to 100%."
      : "Adjust the split: it currently adds to " + formatInputNumber(splitTotal) + "%.";
    elements.splitStatus.classList.toggle("invalid", !validSplit);
    elements.download.disabled = !validSplit;
  }

  function downloadCSV() {
    const splitTotal = state.split.spend + state.split.save + state.split.give;
    if (Math.abs(splitTotal - 100) >= 0.001) return;

    const completed = state.chores.filter((item) => item.complete);
    const dollars = completed.filter((item) => item.kind === "dollars").reduce((sum, item) => sum + item.value, 0);
    const points = completed.filter((item) => item.kind === "points").reduce((sum, item) => sum + item.value, 0);
    const rows = [
      ["MoneyMuncher Family Chore Plan"],
      ["Chore", "Status", "Reward", "Unit"],
      ...state.chores.map((item) => [item.title, item.complete ? "Complete" : "Not complete", item.value, item.kind]),
      [],
      ["Completed dollars", dollars],
      ["Completed points", points],
      ["Spend percentage", state.split.spend + "%", "Spend amount", money(dollars * state.split.spend / 100)],
      ["Save percentage", state.split.save + "%", "Save amount", money(dollars * state.split.save / 100)],
      ["Give percentage", state.split.give + "%", "Give amount", money(dollars * state.split.give / 100)]
    ];
    const csv = rows.map((row) => row.map(csvCell).join(",")).join("\r\n");
    const blob = new Blob(["\ufeff" + csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = "moneymuncher-family-chore-plan.csv";
    document.body.appendChild(link);
    link.click();
    link.remove();
    window.setTimeout(() => URL.revokeObjectURL(url), 0);
  }

  function csvCell(value) {
    const text = String(value == null ? "" : value);
    return /[",\r\n]/.test(text) ? '"' + text.replace(/"/g, '""') + '"' : text;
  }

  function money(value) {
    return "$" + Number(value || 0).toFixed(2);
  }

  function formatInputNumber(value) {
    return Number.isInteger(Number(value)) ? String(Number(value)) : Number(value).toFixed(2).replace(/0+$/, "").replace(/\.$/, "");
  }

  function escapeHTML(value) {
    return String(value).replace(/[&<>"]/g, (character) => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;"
    })[character]);
  }

  function readState() {
    try {
      const raw = window.localStorage.getItem(storageKey);
      return raw ? JSON.parse(raw) : null;
    } catch (error) {
      return null;
    }
  }

  function saveState() {
    try {
      window.localStorage.setItem(storageKey, JSON.stringify(state));
    } catch (error) {
      // The planner continues to work for the current page if storage is unavailable.
    }
  }
})();
