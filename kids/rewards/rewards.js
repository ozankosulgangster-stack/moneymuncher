const badges = [
  {
    id: "smart-saver",
    icon: "SS",
    name: "Smart Saver",
    price: 50,
    type: "Shop Badge",
    description: "For kids who protect future goals before spending everything today."
  },
  {
    id: "budget-builder",
    icon: "BB",
    name: "Budget Builder",
    price: 75,
    type: "Shop Badge",
    description: "For planning spending before the coins leave your wallet."
  },
  {
    id: "needs-wants-pro",
    icon: "NW",
    name: "Needs vs Wants Pro",
    price: 40,
    type: "Shop Badge",
    description: "For spotting the difference between must-have and nice-to-have."
  },
  {
    id: "classroom-captain",
    icon: "CC",
    name: "Classroom Captain",
    price: 100,
    type: "Team Badge",
    description: "For comparing price, quality, and need before spending class coins."
  },
  {
    id: "family-helper",
    icon: "FH",
    name: "Family Helper",
    price: 60,
    type: "Family Badge",
    description: "For turning everyday choices into helpful family money talks."
  },
  {
    id: "golden-dino",
    icon: "GD",
    name: "Golden Dino",
    price: 125,
    type: "Special Badge",
    description: "A shiny badge for steady learners who keep earning and saving."
  }
];

function $(id) {
  return document.getElementById(id);
}

function money() {
  return window.MoneyMuncher;
}

function progress() {
  return money().get();
}

function ownedIds(p) {
  return Array.from(new Set([].concat(p.badges || [], p.shopBadges || [])));
}

function renderWallet() {
  const p = progress();
  const owned = ownedIds(p);
  $("coinBalance").textContent = p.coins || 0;
  $("ownedCount").textContent = owned.length + " owned";
}

function renderBadges() {
  const p = progress();
  const owned = ownedIds(p);
  const grid = $("badgeGrid");
  grid.innerHTML = "";

  badges.forEach((badge) => {
    const isOwned = owned.includes(badge.id);
    const canBuy = (p.coins || 0) >= badge.price;
    const card = document.createElement("article");
    card.className = "badge-card";
    card.innerHTML = `
      <span class="badge-icon">${badge.icon}</span>
      <h3>${badge.name}</h3>
      <div class="badge-meta">
        <span>${badge.price} coins</span>
        <span>${badge.type}</span>
      </div>
      <p>${badge.description}</p>
      <button class="${isOwned ? "secondary" : "primary"}" type="button" ${isOwned || !canBuy ? "disabled" : ""}>
        ${isOwned ? "Owned" : canBuy ? "Buy Badge" : "Need more coins"}
      </button>
    `;
    card.querySelector("button").addEventListener("click", () => {
      const result = money().buyBadge(badge);
      renderAll(result.message);
    });
    grid.appendChild(card);
  });
}

function renderTransactions(message) {
  const p = progress();
  const list = $("transactionList");
  const transactions = (p.transactions || []).slice(-8).reverse();
  list.innerHTML = "";

  if (message) {
    const li = document.createElement("li");
    li.innerHTML = `<span>${message}</span><strong class="earn">Updated</strong>`;
    list.appendChild(li);
  }

  if (!transactions.length) {
    const li = document.createElement("li");
    li.innerHTML = "<span>No coin activity yet.</span><strong>Start playing</strong>";
    list.appendChild(li);
    return;
  }

  transactions.forEach((tx) => {
    const li = document.createElement("li");
    const cls = tx.type === "earn" ? "earn" : "spend";
    const sign = tx.type === "earn" ? "+" : "-";
    li.innerHTML = `<span>${tx.reason || tx.source}</span><strong class="${cls}">${sign}${tx.amount}</strong>`;
    list.appendChild(li);
  });
}

function renderAll(message) {
  renderWallet();
  renderBadges();
  renderTransactions(message);
}

$("starterCoinsBtn").addEventListener("click", () => {
  const p = progress();
  const alreadyClaimed = (p.transactions || []).some((tx) => tx.source === "starter-wallet");
  if (alreadyClaimed) {
    renderAll("Starter coins already claimed.");
    return;
  }
  money().earnCoins(35, "starter-wallet", "Starter coins for the badge shop");
  renderAll("Starter coins added.");
});

renderAll();
