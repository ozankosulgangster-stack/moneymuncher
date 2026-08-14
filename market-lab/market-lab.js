(function () {
  "use strict";

  var STARTING_COINS = 10000;
  var todayIndex = 27;
  var wallet = STARTING_COINS;
  var positions = [];
  var currentUser = null;
  var db = null;

  var assets = [
    { symbol: "VOO", name: "Vanguard S&P 500 ETF", type: "ETF", basePrice: 514.42, volatility: 0.9, momentum: 0.46, lesson: "An ETF holds many companies, so one company has less power to move the whole basket." },
    { symbol: "AAPL", name: "Apple", type: "Stock", basePrice: 196.12, volatility: 1.35, momentum: 0.34, lesson: "A single company can move faster than an ETF because all the coins depend on one business." },
    { symbol: "MSFT", name: "Microsoft", type: "Stock", basePrice: 475.88, volatility: 1.15, momentum: 0.51, lesson: "Large companies can still jump around when expectations change." },
    { symbol: "TSLA", name: "Tesla", type: "Stock", basePrice: 178.64, volatility: 2.4, momentum: -0.18, lesson: "High-volatility stocks can rise quickly, but they can also drop quickly." },
    { symbol: "QQQ", name: "Nasdaq 100 ETF", type: "ETF", basePrice: 462.35, volatility: 1.25, momentum: 0.58, lesson: "Some ETFs focus on one style of company, so they may be less balanced than broad ETFs." },
    { symbol: "DIS", name: "Disney", type: "Stock", basePrice: 102.2, volatility: 1.45, momentum: 0.06, lesson: "Brands kids know are not automatically safer investments." }
  ];

  function $(id) { return document.getElementById(id); }

  function getAsset(symbol) {
    return assets.find(function (asset) { return asset.symbol === symbol; });
  }

  function hashSymbol(symbol) {
    return symbol.split("").reduce(function (sum, char) { return sum + char.charCodeAt(0); }, 0);
  }

  function getPrice(symbol, day) {
    var asset = getAsset(symbol);
    var seed = hashSymbol(symbol);
    var d = typeof day === "number" ? day : todayIndex;
    var seasonal = Math.sin((d + seed) * 0.47) * asset.volatility;
    var wiggle = Math.cos((d * 1.7 + seed) * 0.29) * asset.volatility * 0.58;
    var drift = d * asset.momentum * 0.26;
    var shock = Math.sin((d + seed) * 0.11) * asset.volatility * 0.35;
    return Math.max(2, asset.basePrice + seasonal + wiggle + drift + shock);
  }

  function getHistory(symbol, days) {
    var count = days || 28;
    var start = todayIndex - count + 1;
    return Array.from({ length: count }, function (_, index) {
      return getPrice(symbol, start + index);
    });
  }

  function probability(symbol) {
    var asset = getAsset(symbol);
    var history = getHistory(symbol, 20);
    var first = history[0];
    var last = history[history.length - 1];
    var momentum = (last - first) / first;
    var swings = history.slice(1).map(function (price, index) {
      return Math.abs((price - history[index]) / history[index]);
    });
    var avgSwing = swings.reduce(function (sum, value) { return sum + value; }, 0) / swings.length;
    var raw = 0.5 + momentum * 2.4 - avgSwing * asset.volatility * 0.38 + asset.momentum * 0.03;
    var up = Math.max(0.24, Math.min(0.76, raw));
    return {
      up: up,
      down: 1 - up,
      confidence: avgSwing > 0.015 || asset.volatility > 1.8 ? "low" : up > 0.58 || up < 0.42 ? "medium" : "low",
      label: up >= 0.58 ? "More likely up" : up <= 0.42 ? "More likely down" : "Mixed"
    };
  }

  function formatCoins(value) {
    return Math.round(value).toLocaleString() + " coins";
  }

  function formatNumber(value) {
    return value.toLocaleString(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });
  }

  function portfolioValue(day) {
    return positions.reduce(function (sum, position) {
      return sum + position.units * getPrice(position.symbol, day);
    }, 0);
  }

  function portfolioRows() {
    return positions.map(function (position, index) {
      var asset = getAsset(position.symbol);
      var currentValue = position.units * getPrice(position.symbol);
      var gain = currentValue - position.coinsInvested;
      return Object.assign({}, position, {
        index: index,
        asset: asset,
        currentValue: currentValue,
        gain: gain,
        prob: probability(position.symbol)
      });
    });
  }

  function portfolioDoc() {
    return db.collection("players").doc(currentUser.uid).collection("marketLab").doc("portfolio");
  }

  function setStatus(message) {
    $("statusLine").textContent = message;
  }

  function defaultPortfolio() {
    return { wallet: STARTING_COINS, positions: [], updatedAt: null };
  }

  function loadPortfolio() {
    setStatus("Loading saved choices from Firebase...");
    return portfolioDoc().get().then(function (doc) {
      var data = doc.exists ? doc.data() : defaultPortfolio();
      wallet = Number(data.wallet || STARTING_COINS);
      positions = Array.isArray(data.positions) ? data.positions.map(function (position) {
        return {
          id: position.id || ("pos_" + Date.now() + "_" + Math.random().toString(16).slice(2)),
          symbol: position.symbol,
          coinsInvested: Number(position.coinsInvested || 0),
          units: Number(position.units || 0),
          entryPrice: Number(position.entryPrice || getPrice(position.symbol))
        };
      }).filter(function (position) {
        return getAsset(position.symbol) && position.coinsInvested > 0 && position.units > 0;
      }) : [];
      render();
      setStatus("Saved choices loaded. This is a virtual learning simulation.");
    }).catch(function (error) {
      console.error("[MarketLab] load failed", error);
      setStatus("Could not load Firebase portfolio. Try refreshing after sign-in.");
    });
  }

  function savePortfolio(message) {
    if (!currentUser) return Promise.resolve();
    setStatus(message || "Saving choices to Firebase...");
    return portfolioDoc().set({
      wallet: wallet,
      positions: positions,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true }).then(function () {
      setStatus("Saved to Firebase. This is virtual practice, not financial advice.");
    }).catch(function (error) {
      console.error("[MarketLab] save failed", error);
      setStatus("Could not save to Firebase. Your screen still shows the latest local action.");
    });
  }

  function renderSelectors() {
    $("assetSelect").innerHTML = assets.map(function (asset) {
      return "<option value=\"" + asset.symbol + "\">" + asset.symbol + " - " + asset.name + "</option>";
    }).join("");
  }

  function renderAssetList() {
    $("assetList").innerHTML = assets.map(function (asset) {
      var price = getPrice(asset.symbol);
      var yesterday = getPrice(asset.symbol, todayIndex - 1);
      var move = price - yesterday;
      var prob = probability(asset.symbol);
      return [
        "<article class=\"asset-card\">",
          "<div>",
            "<strong>", asset.symbol, " - ", asset.name, "</strong>",
            "<p>", prob.label, " - ", Math.round(prob.up * 100), "% up estimate - ", prob.confidence, " confidence</p>",
          "</div>",
          "<div>",
            "<strong>", formatNumber(price), "</strong>",
            "<p class=\"", move >= 0 ? "positive" : "negative", "\">", move >= 0 ? "+" : "", formatNumber(move), "</p>",
          "</div>",
        "</article>"
      ].join("");
    }).join("");
  }

  function renderLearningCards() {
    $("learningCards").innerHTML = assets.slice(0, 4).map(function (asset) {
      var prob = probability(asset.symbol);
      return [
        "<article class=\"learning-card\">",
          "<strong>", asset.symbol, " - ", prob.label, "</strong>",
          "<p>", asset.lesson, "</p>",
          "<p>", Math.round(prob.up * 100), "% up / ", Math.round(prob.down * 100), "% down estimate. This is a learning signal, not a prediction.</p>",
        "</article>"
      ].join("");
    }).join("");
  }

  function renderHoldings() {
    var rows = portfolioRows();
    if (!rows.length) {
      $("holdingsBody").innerHTML = "<tr><td colspan=\"7\">No holdings yet. Pick an asset and buy with virtual coins.</td></tr>";
      return;
    }
    $("holdingsBody").innerHTML = rows.map(function (row) {
      return [
        "<tr>",
          "<td><strong>", row.asset.symbol, "</strong><br><span class=\"muted\">", row.asset.name, "</span></td>",
          "<td>", row.asset.type, "</td>",
          "<td>", formatCoins(row.coinsInvested), "</td>",
          "<td>", formatCoins(row.currentValue), "</td>",
          "<td class=\"", row.gain >= 0 ? "positive" : "negative", "\">", row.gain >= 0 ? "+" : "", formatCoins(row.gain), "</td>",
          "<td>", row.prob.label, "<br><span class=\"muted\">", Math.round(row.prob.up * 100), "% up</span></td>",
          "<td><button class=\"sell-btn\" type=\"button\" data-position-id=\"", row.id, "\">Sell</button></td>",
        "</tr>"
      ].join("");
    }).join("");
  }

  function renderSummary() {
    var rows = portfolioRows();
    var positionsValue = portfolioValue(todayIndex);
    var total = wallet + positionsValue;
    var weighted = rows.length ? rows.reduce(function (sum, row) {
      return sum + row.prob.up * row.currentValue;
    }, 0) / positionsValue : 0.5;
    $("totalValue").textContent = formatCoins(total);
    $("walletBalance").textContent = formatCoins(wallet) + " wallet";
    $("portfolioOutlook").textContent = weighted >= 0.58 ? "Bright" : weighted <= 0.42 ? "Careful" : "Mixed";
    $("meterFill").style.width = Math.round(weighted * 100) + "%";
  }

  function renderReport() {
    var rows = portfolioRows();
    var total = wallet + portfolioValue(todayIndex);
    var start = wallet + portfolioValue(todayIndex - 5);
    var weeklyMove = total - start;
    var best = rows.slice().sort(function (a, b) { return b.gain - a.gain; })[0];
    var worst = rows.slice().sort(function (a, b) { return a.gain - b.gain; })[0];
    $("weeklyReport").textContent = [
      "MoneyMuncher Weekly Report",
      "",
      "Member: " + (currentUser && currentUser.email ? currentUser.email : "member"),
      "Portfolio value: " + formatCoins(total),
      "Weekly change: " + (weeklyMove >= 0 ? "+" : "") + formatCoins(weeklyMove),
      "Wallet left: " + formatCoins(wallet),
      "",
      "Best helper: " + (best ? best.asset.symbol + " (" + (best.gain >= 0 ? "+" : "") + formatCoins(best.gain) + ")" : "No holdings yet"),
      "Biggest drag: " + (worst ? worst.asset.symbol + " (" + (worst.gain >= 0 ? "+" : "") + formatCoins(worst.gain) + ")" : "No holdings yet"),
      "",
      "Learning note:",
      "ETF baskets can feel steadier because they spread coins across many companies.",
      "",
      "Safety note:",
      "This is a virtual learning simulation. It is not financial advice and does not use real money."
    ].join("\n");
  }

  function drawChart() {
    var canvas = $("portfolioChart");
    var ctx = canvas.getContext("2d");
    var ratio = window.devicePixelRatio || 1;
    var cssWidth = canvas.clientWidth || 1000;
    var cssHeight = canvas.clientHeight || 260;
    canvas.width = Math.floor(cssWidth * ratio);
    canvas.height = Math.floor(cssHeight * ratio);
    ctx.scale(ratio, ratio);
    ctx.clearRect(0, 0, cssWidth, cssHeight);

    var values = Array.from({ length: 28 }, function (_, index) {
      var day = todayIndex - 27 + index;
      return wallet + portfolioValue(day);
    });
    var min = Math.min.apply(null, values) * 0.997;
    var max = Math.max.apply(null, values) * 1.003;
    var pad = 22;
    var chartWidth = cssWidth - pad * 2;
    var chartHeight = cssHeight - pad * 2;

    ctx.strokeStyle = "rgba(23,32,42,.12)";
    ctx.lineWidth = 1;
    for (var i = 0; i < 4; i += 1) {
      var y = pad + (chartHeight / 3) * i;
      ctx.beginPath();
      ctx.moveTo(pad, y);
      ctx.lineTo(cssWidth - pad, y);
      ctx.stroke();
    }

    ctx.beginPath();
    values.forEach(function (value, index) {
      var x = pad + (chartWidth / (values.length - 1)) * index;
      var y = pad + chartHeight - ((value - min) / (max - min || 1)) * chartHeight;
      if (index === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.strokeStyle = "#17202a";
    ctx.lineWidth = 4;
    ctx.lineJoin = "round";
    ctx.lineCap = "round";
    ctx.stroke();
  }

  function render() {
    renderSummary();
    renderAssetList();
    renderLearningCards();
    renderHoldings();
    renderReport();
    drawChart();
  }

  function showGate() {
    $("gate").classList.remove("hidden");
    $("labApp").classList.add("hidden");
    $("signOutBtn").classList.add("hidden");
    $("memberStatus").textContent = "Members only";
  }

  function showApp(user) {
    currentUser = user;
    db = firebase.firestore();
    $("gate").classList.add("hidden");
    $("labApp").classList.remove("hidden");
    $("signOutBtn").classList.remove("hidden");
    $("memberStatus").textContent = (user.email || "Member") + " - cloud saved";
    loadPortfolio();
  }

  function signIn(email, password) {
    $("authMessage").textContent = "Signing in...";
    MoneyMuncher.signIn(email, password).catch(function (error) {
      $("authMessage").textContent = error.message;
    });
  }

  function signUp(email, password) {
    $("authMessage").textContent = "Creating account...";
    MoneyMuncher.signUp(email, password, { name: email.split("@")[0], role: "Parent Guide" }).catch(function (error) {
      $("authMessage").textContent = error.message;
    });
  }

  function resetMemberPassword(email) {
    var resetButton = $("memberForgotPasswordBtn");
    if (!email) {
      $("authMessage").textContent = "Enter your email first, then tap Forgot password.";
      return;
    }

    resetButton.disabled = true;
    $("authMessage").textContent = "Sending password reset email...";
    MoneyMuncher.resetPassword(email).then(function () {
      $("authMessage").textContent = "Password reset email sent. Please check your inbox.";
    }).catch(function (error) {
      $("authMessage").textContent = error.message;
    }).then(function () {
      resetButton.disabled = false;
    });
  }

  function buySelectedAsset() {
    var symbol = $("assetSelect").value;
    var coins = Math.max(10, Number($("coinInput").value || 0));
    if (coins > wallet) {
      setStatus("Not enough virtual coins in your wallet.");
      return;
    }
    var price = getPrice(symbol);
    wallet -= coins;
    positions.push({
      id: "pos_" + Date.now() + "_" + Math.random().toString(16).slice(2),
      symbol: symbol,
      coinsInvested: coins,
      units: coins / price,
      entryPrice: price
    });
    render();
    savePortfolio("Saving virtual buy to Firebase...");
  }

  function sellPosition(id) {
    var position = positions.find(function (item) { return item.id === id; });
    if (!position) return;
    wallet += position.units * getPrice(position.symbol);
    positions = positions.filter(function (item) { return item.id !== id; });
    render();
    savePortfolio("Saving virtual sale to Firebase...");
  }

  document.addEventListener("DOMContentLoaded", function () {
    renderSelectors();
    render();

    $("memberSignInBtn").addEventListener("click", function () {
      signIn($("memberEmail").value.trim(), $("memberPassword").value);
    });
    $("memberSignUpBtn").addEventListener("click", function () {
      signUp($("memberEmail").value.trim(), $("memberPassword").value);
    });
    $("memberForgotPasswordBtn").addEventListener("click", function () {
      resetMemberPassword($("memberEmail").value.trim());
    });
    $("signOutBtn").addEventListener("click", function () {
      MoneyMuncher.signOut();
    });
    $("buyBtn").addEventListener("click", buySelectedAsset);
    $("holdingsBody").addEventListener("click", function (event) {
      var button = event.target.closest("[data-position-id]");
      if (button) sellPosition(button.getAttribute("data-position-id"));
    });
    window.addEventListener("resize", drawChart);

    firebase.auth().onAuthStateChanged(function (user) {
      if (user) showApp(user);
      else showGate();
    });
  });
})();
