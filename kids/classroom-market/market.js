const rounds = [
  {
    title: "Art Cart Restock",
    prompt: "Your class needs supplies for a poster project. Pick one bundle.",
    options: [
      {
        name: "Marker Mega Pack",
        price: 18,
        need: 8,
        quality: 8,
        value: 7,
        tag: "Best balance",
        details: "Enough colors for every team, sturdy tips, and still leaves coins for later.",
        feedback: "Dino Munch likes this balance: useful, good quality, and not the most expensive."
      },
      {
        name: "Glitter Deluxe Box",
        price: 24,
        need: 3,
        quality: 7,
        value: 3,
        tag: "Fun want",
        details: "Sparkly and exciting, but the class still needs basic supplies first.",
        feedback: "Fun is allowed, but this is more want than need. The budget gets tight fast."
      },
      {
        name: "Budget Pencils",
        price: 8,
        need: 7,
        quality: 4,
        value: 6,
        tag: "Cheap pick",
        details: "Low price, but they break often and may not last the whole project.",
        feedback: "Cheap is not always best. Low quality can mean buying twice."
      }
    ]
  },
  {
    title: "Science Fair Table",
    prompt: "Your team needs supplies for fair displays and experiments.",
    options: [
      {
        name: "Display Boards",
        price: 14,
        need: 9,
        quality: 7,
        value: 8,
        tag: "Strong need",
        details: "Every group needs a board, and these are sturdy enough to reuse.",
        feedback: "Great team thinking. This solves a real class need and keeps spending controlled."
      },
      {
        name: "Tiny Volcano Kit",
        price: 20,
        need: 4,
        quality: 8,
        value: 4,
        tag: "One-group item",
        details: "Cool for one group, but it does not help the whole class equally.",
        feedback: "Quality is high, but the need is narrow. A class purchase should help more students."
      },
      {
        name: "Tape And Labels",
        price: 9,
        need: 8,
        quality: 6,
        value: 9,
        tag: "High value",
        details: "Simple supplies that every group can use for a small price.",
        feedback: "Excellent value. Small purchases can carry a big classroom job."
      }
    ]
  },
  {
    title: "Reading Nook Upgrade",
    prompt: "The reading corner needs an upgrade before library week.",
    options: [
      {
        name: "Cozy Floor Cushions",
        price: 16,
        need: 7,
        quality: 8,
        value: 8,
        tag: "Reusable",
        details: "Comfortable, washable, and useful for reading circles all year.",
        feedback: "Reusable purchases are powerful. Dino Munch sees long-term value here."
      },
      {
        name: "Prize Sticker Tower",
        price: 12,
        need: 3,
        quality: 5,
        value: 4,
        tag: "Short-term fun",
        details: "Fun rewards, but they disappear quickly and do not improve the nook.",
        feedback: "This creates quick excitement, but not much long-term classroom value."
      },
      {
        name: "Book Repair Kit",
        price: 10,
        need: 8,
        quality: 7,
        value: 9,
        tag: "Protects books",
        details: "Repairs torn pages and keeps class books usable for more readers.",
        feedback: "Smart saver move. Protecting what you already own is a money skill."
      }
    ]
  }
];

const state = {
  round: 0,
  coins: 40,
  need: 0,
  quality: 0,
  value: 0,
  receipt: [],
  active: false
};

function $(id) {
  return document.getElementById(id);
}

function renderScores() {
  $("coinsLeft").textContent = state.coins;
  $("needScore").textContent = state.need;
  $("qualityScore").textContent = state.quality;
  $("valueScore").textContent = state.value;
}

function renderReceipt() {
  const list = $("receiptList");
  list.innerHTML = "";
  if (!state.receipt.length) {
    const li = document.createElement("li");
    li.textContent = "No team purchases yet.";
    list.appendChild(li);
    return;
  }
  state.receipt.forEach((item) => {
    const li = document.createElement("li");
    li.textContent = `${item.round}: ${item.name} (${item.price} coins)`;
    list.appendChild(li);
  });
}

function renderRound() {
  const round = rounds[state.round];
  $("roundEyebrow").textContent = `Round ${state.round + 1} of ${rounds.length}`;
  $("roundTitle").textContent = round.title;
  $("roundPrompt").textContent = round.prompt;

  const grid = $("choiceGrid");
  grid.innerHTML = "";

  round.options.forEach((option) => {
    const card = document.createElement("article");
    card.className = "choice-card";
    const disabled = option.price > state.coins ? "disabled" : "";
    card.innerHTML = `
      <span class="tag">${option.tag}</span>
      <h3>${option.name}</h3>
      <div class="stats-row">
        <span>${option.price} coins</span>
        <span>Need ${option.need}/10</span>
        <span>Quality ${option.quality}/10</span>
      </div>
      <p>${option.details}</p>
      <button class="primary" type="button" ${disabled}>Choose this</button>
    `;
    card.querySelector("button").addEventListener("click", () => chooseOption(option));
    grid.appendChild(card);
  });
}

function chooseOption(option) {
  if (!state.active || option.price > state.coins) return;

  const round = rounds[state.round];
  state.coins -= option.price;
  state.need += option.need;
  state.quality += option.quality;
  state.value += option.value;
  state.receipt.push({ round: round.title, name: option.name, price: option.price });

  $("feedback").textContent = option.feedback;
  state.round += 1;
  renderScores();
  renderReceipt();

  if (state.round >= rounds.length) {
    finishGame();
  } else {
    setTimeout(renderRound, 450);
  }
}

function finishGame() {
  state.active = false;
  const total = state.need + state.quality + state.value + state.coins;
  let title = "Smart Team Shopper";
  let reward = 12;
  if (total >= 92) title = "Classroom Market Captain";
  if (total >= 92) reward = 25;
  else if (total >= 82) reward = 18;
  else if (total < 75) title = "Budget Builder In Training";

  if (window.MoneyMuncher && window.MoneyMuncher.earnCoins) {
    window.MoneyMuncher.earnCoins(reward, "classroom-market", title + " reward");
  }

  $("roundEyebrow").textContent = "Market complete";
  $("roundTitle").textContent = title;
  $("roundPrompt").textContent = `Your team kept ${state.coins} coins and scored ${state.need} need, ${state.quality} quality, and ${state.value} value points. You earned ${reward} wallet coins.`;
  $("choiceGrid").innerHTML = "";
  $("feedback").textContent = "Dino Munch says: the best class purchase is not always the cheapest one. Compare price, quality, and who really needs it. Visit Rewards to spend your coins on badges.";
}

function startGame() {
  state.round = 0;
  state.coins = 40;
  state.need = 0;
  state.quality = 0;
  state.value = 0;
  state.receipt = [];
  state.active = true;
  renderScores();
  renderReceipt();
  renderRound();
  $("feedback").textContent = "Choose the best bundle for your class. Watch the coins, but do not ignore quality or need.";
}

$("startGameBtn").addEventListener("click", startGame);
$("resetGameBtn").addEventListener("click", startGame);

renderScores();
renderReceipt();
