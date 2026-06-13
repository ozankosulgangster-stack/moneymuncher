/* ============================================================
   MoneyMuncher Game Logic
   Reads/writes through MoneyMuncher (Firebase + localStorage).
   ============================================================ */

// --- 0. Helpers ---
function $(id) { return document.getElementById(id); }

const hasMM = typeof window.MoneyMuncher !== 'undefined';

// --- 1. Data ---
const defaultState = { coins: 30, saved: 0, joy: 50, wisdom: 0, currentLevel: 0 };
let state   = { ...defaultState };
let progress = { unlockedLevel: 0, completedLevels: [] };
let account = { id: "", name: "", role: "" };
let selectedRole = localStorage.getItem('moneymuncherRole') || 'Kid Explorer';
let selectedAgePath = localStorage.getItem('moneymuncherAgePath') || 'coin-collectors';

const experienceModes = [
  {
    id: 'Kid Explorer',
    icon: 'KE',
    title: 'Kid Explorer',
    hint: 'Kids get games, tiny quests, and quick wins.',
    badge: 'Kid Explorer mode',
    startLabel: 'Start Game Quest'
  },
  {
    id: 'Parent Guide',
    icon: 'PG',
    title: 'Parent Guide',
    hint: 'Parents get conversation prompts, grocery moments, and no-lecture scripts.',
    badge: 'Parent Guide mode',
    startLabel: 'Open Family Quest'
  },
  {
    id: 'Teacher Captain',
    icon: 'TC',
    title: 'Teacher Captain',
    hint: 'Teachers get classroom quests, team challenges, and discussion-ready prompts.',
    badge: 'Teacher Captain mode',
    startLabel: 'Launch Class Quest'
  },
  {
    id: 'Family Team',
    icon: 'FT',
    title: 'Family Team',
    hint: 'Families get shared challenges that turn everyday choices into teamwork.',
    badge: 'Family Team mode',
    startLabel: 'Start Team Challenge'
  }
];

const agePaths = [
  {
    id: 'coin-collectors',
    icon: '6-8',
    name: 'Coin Collectors',
    ages: 'Ages 6-8',
    summary: 'Needs vs. wants, saving jars, chores, and sharing.',
    topics: ['Needs vs. wants', 'Saving jars', 'Chores', 'Sharing']
  },
  {
    id: 'budget-builders',
    icon: '9-12',
    name: 'Budget Builders',
    ages: 'Ages 9-12',
    summary: 'Allowance planning, goal setting, and comparison shopping.',
    topics: ['Allowance plans', 'Goals', 'Price checks', 'Tradeoffs']
  },
  {
    id: 'money-masters',
    icon: '13-16',
    name: 'Money Masters',
    ages: 'Ages 13-16',
    summary: 'Bank accounts, investing basics, subscriptions, scams, and long-term goals.',
    topics: ['Banking', 'Investing basics', 'Subscriptions', 'Scams']
  }
];

const miniGames = [
  {
    id: 'grocery-dash',
    icon: 'GD',
    title: 'The Grocery Dash',
    audience: ['Kid Explorer', 'Parent Guide', 'Family Team'],
    ages: ['coin-collectors', 'budget-builders'],
    duration: '2-3 min',
    skill: 'Budget choices',
    summary: 'Pick dinner items under a budget and see how smart swaps save coins.',
    levelIndex: 5
  },
  {
    id: 'subscription-sneak',
    icon: 'SS',
    title: 'Subscription Sneak',
    audience: ['Kid Explorer', 'Parent Guide', 'Teacher Captain', 'Family Team'],
    ages: ['money-masters'],
    duration: '3 min',
    skill: 'Recurring costs',
    summary: 'Spot sneaky monthly charges before they munch the whole allowance.',
    levelIndex: 6
  },
  {
    id: 'classroom-market',
    icon: 'CM',
    title: 'Classroom Market',
    audience: ['Teacher Captain', 'Family Team'],
    ages: ['coin-collectors', 'budget-builders', 'money-masters'],
    duration: '2 min',
    skill: 'Compare value',
    summary: 'Teams compare prices, quality, and needs before spending class coins.',
    levelIndex: 7,
    href: '/kids/classroom-market/'
  }
];

// --- 2. Load from MoneyMuncher (or keep local defaults) ---
function loadFromManager() {
  if (!hasMM) return;
  var p = MoneyMuncher.get();

  state.coins       = (typeof p.coins === 'number')       ? p.coins       : defaultState.coins;
  state.saved       = (typeof p.saved === 'number')       ? p.saved       : defaultState.saved;
  state.joy         = (typeof p.joy === 'number')         ? p.joy         : defaultState.joy;
  state.wisdom      = (typeof p.wisdom === 'number')      ? p.wisdom      : defaultState.wisdom;
  state.currentLevel = (typeof p.currentLevel === 'number') ? p.currentLevel : defaultState.currentLevel;

  progress.unlockedLevel   = (typeof p.unlockedLevel === 'number')   ? p.unlockedLevel   : 0;
  progress.completedLevels = Array.isArray(p.completedLevels) ? [...p.completedLevels] : [];

  // Local name/role display
  var sess = JSON.parse(localStorage.getItem('moneymuncherSession') || 'null');
  if (sess && sess.name) account = sess;
}

// --- 3. Save back to MoneyMuncher ---
function sync() {
  if (!hasMM) return;
  MoneyMuncher.set({
    coins: state.coins,
    saved: state.saved,
    joy: state.joy,
    wisdom: state.wisdom,
    currentLevel: state.currentLevel,
    unlockedLevel: progress.unlockedLevel,
    completedLevels: progress.completedLevels
  });
}

// --- 4. Local session (for name/role display) ---
function saveSession()  { localStorage.setItem('moneymuncherSession', JSON.stringify(account)); }
function clearSession() { localStorage.removeItem('moneymuncherSession'); }
function restoreSession() {
  var s = JSON.parse(localStorage.getItem('moneymuncherSession') || 'null');
  if (s && s.name) account = s;
}

// --- 5. Levels (unchanged) ---
const levels = [
  {
    icon: "🍿", name: "Snack Shop", skill: "Needs vs wants",
    eyebrow: "Level 1: Snack Shop Saturday",
    title: "You got 30 coins!",
    text: "You helped a neighbor water plants and earned 30 coins. What will you do first?",
    choices: [
      { label: "Save 10 coins", detail: "Future-you gets stronger.", coins: -10, saved: 10, joy: 2, wisdom: 12, feedback: "Smart start. Saving is paying your future self first." },
      { label: "Buy mega candy", detail: "Fun now, coins gone fast.", coins: -18, saved: 0, joy: 18, wisdom: 4, feedback: "Candy joy is real — but it fades. Was it worth more than your next goal?" },
      { label: "Split: save, spend, share", detail: "Balanced money move.", coins: -15, saved: 8, joy: 10, wisdom: 16, feedback: "That’s a power combo: enjoy today, protect tomorrow, help someone too." }
    ]
  },
  {
    icon: "🛍️", name: "Toy Market", skill: "Impulse control",
    eyebrow: "Level 2: Toy Market Temptation",
    title: "A shiny toy appears!",
    text: "The toy costs 25 coins. You want it, but you also want a bigger skateboard later.",
    choices: [
      { label: "Wait 24 hours", detail: "Test if it is a want or a wow.", coins: 0, saved: 5, joy: -2, wisdom: 18, feedback: "Waiting is a money superpower. Some wants shrink when you give them time." },
      { label: "Buy it now", detail: "Instant excitement.", coins: -25, saved: 0, joy: 16, wisdom: 3, feedback: "Impulse buys feel fun. Now the lesson: what goal got delayed?" },
      { label: "Compare prices", detail: "Hunt for a better deal.", coins: -17, saved: 3, joy: 10, wisdom: 14, feedback: "Deal detective! Comparing prices keeps more coins in your pocket." }
    ]
  },
  {
    icon: "🏦", name: "Savings Bank", skill: "Goals and patience",
    eyebrow: "Level 3: Savings Bank Bridge",
    title: "Your skateboard goal needs 60 coins.",
    text: "You can earn slowly, save regularly, or borrow from future-you. What is your move?",
    choices: [
      { label: "Save every week", detail: "Small steps, big goal.", coins: -8, saved: 18, joy: 2, wisdom: 18, feedback: "Consistency is quiet magic. Goals become real through repeated small choices." },
      { label: "Borrow from future-you", detail: "Fast now, harder later.", coins: 12, saved: -5, joy: 12, wisdom: 5, feedback: "Borrowing can help, but future-you needs a repayment plan." },
      { label: "Create a chore plan", detail: "Earn more with effort.", coins: 15, saved: 10, joy: 6, wisdom: 16, feedback: "Income idea unlocked. Earning is one side of smart money." }
    ]
  },
  {
    icon: "🎁", name: "Sharing Square", skill: "Giving and community",
    eyebrow: "Level 4: Sharing Square",
    title: "A class fundraiser needs help.",
    text: "You care about the cause, but you also have your own goal. How do you balance it?",
    choices: [
      { label: "Give a little", detail: "Help without draining goals.", coins: -6, saved: 0, joy: 12, wisdom: 14, feedback: "Generosity works best when it is thoughtful and sustainable." },
      { label: "Volunteer time", detail: "Value is not only money.", coins: 0, saved: 4, joy: 10, wisdom: 17, feedback: "Beautiful move. Time, care, and skills are powerful contributions too." },
      { label: "Give everything", detail: "Kind heart, empty wallet.", coins: -20, saved: -8, joy: 18, wisdom: 7, feedback: "Kindness matters — and so does keeping promises to yourself." }
    ]
  },
  {
    icon: "🏡", name: "Family Budget", skill: "Planning together",
    eyebrow: "Level 5: Family Budget Builder",
    title: "Plan a weekly family snack budget.",
    text: "You need snacks for 5 days, a small treat, and some savings. What plan wins?",
    choices: [
      { label: "Plan before shopping", detail: "List, budget, compare.", coins: -12, saved: 12, joy: 8, wisdom: 22, feedback: "Budget brain activated. A plan helps families spend with less stress." },
      { label: "Buy random snacks", detail: "Fun but risky.", coins: -24, saved: 0, joy: 14, wisdom: 5, feedback: "Random can be fun, but budgets protect the whole week." },
      { label: "Let kids vote", detail: "Community choice.", coins: -16, saved: 6, joy: 16, wisdom: 18, feedback: "Great family move: shared choices build money confidence and trust." }
    ]
  },
  {
    icon: "$", name: "Grocery Dash", skill: "Budget shopping",
    eyebrow: "Mini-Game: The Grocery Dash",
    title: "Can you build dinner under 20 coins?",
    text: "Choose dinner items for the table. You need a main, a veggie, and a treat without blowing the budget.",
    choices: [
      { label: "Rice, beans, apples", detail: "Filling, balanced, under budget.", coins: -14, saved: 6, joy: 9, wisdom: 20, feedback: "Grocery dash win. You fed the team and kept coins for later." },
      { label: "Pizza, soda, cookies", detail: "Fun, but budget-busting.", coins: -25, saved: 0, joy: 18, wisdom: 6, feedback: "Tasty, but the budget got munched. What one swap could save coins?" },
      { label: "Pasta, carrots, frozen fruit", detail: "Smart swaps, happy table.", coins: -18, saved: 3, joy: 13, wisdom: 18, feedback: "Smart shopping. You compared choices and made the budget stretch." }
    ]
  },
  {
    icon: "$", name: "Subscription Sneak", skill: "Recurring costs",
    eyebrow: "Mini-Game: Subscription Sneak",
    title: "A free trial is about to renew.",
    text: "The app looked free, but tomorrow it starts costing 8 coins every month. What do you do?",
    choices: [
      { label: "Cancel before renewal", detail: "Keep the coins for your goal.", coins: 0, saved: 8, joy: 3, wisdom: 20, feedback: "Sharp eye. Subscriptions are small bites that add up." },
      { label: "Ignore it", detail: "Future coins disappear.", coins: -8, saved: 0, joy: -2, wisdom: 5, feedback: "That is how sneaky costs work. Calendar reminders protect your money." },
      { label: "Ask if it is worth it", detail: "Review value first.", coins: -4, saved: 4, joy: 5, wisdom: 16, feedback: "Good review. A subscription should earn its place every month." }
    ]
  },
  {
    icon: "$", name: "Classroom Market", skill: "Compare value",
    eyebrow: "Mini-Game: Classroom Market",
    title: "Your team has 40 class coins.",
    text: "Pick supplies for a class celebration. The goal is value, not just the lowest price.",
    choices: [
      { label: "Compare three options", detail: "Price, quality, quantity.", coins: -24, saved: 10, joy: 12, wisdom: 22, feedback: "Captain move. Comparing value beats guessing." },
      { label: "Buy the first bundle", detail: "Fast, but unknown value.", coins: -34, saved: 0, joy: 8, wisdom: 7, feedback: "Fast choices can cost more. A quick comparison would help the team." },
      { label: "Vote, then budget", detail: "Shared plan before spending.", coins: -28, saved: 6, joy: 16, wisdom: 18, feedback: "Nice team process. Shared choices build trust and better budgets." }
    ]
  }
];

// --- 6. Auth wiring (only attaches if buttons exist) ---
document.addEventListener('DOMContentLoaded', function() {
  var signUpBtn  = $('signUpBtn');
  var signInBtn  = $('signInBtn');
  var forgotPasswordBtn = $('forgotPasswordBtn');
  var nameIn     = $('nameInput');
  var roleIn     = $('roleInput');
  var emailIn    = $('emailInput');
  var passIn     = $('passInput');

  if (roleIn) {
    roleIn.value = selectedRole;
    roleIn.addEventListener('change', function() {
      selectedRole = roleIn.value;
      localStorage.setItem('moneymuncherRole', selectedRole);
      renderPlaySetup();
      renderMiniGames();
    });
  }

  if (signUpBtn && emailIn && passIn) {
    signUpBtn.addEventListener('click', function() {
      var em = emailIn.value.trim(), pw = passIn.value;
      var profile = {
        name: (nameIn && nameIn.value.trim()) || em.split('@')[0],
        role: (roleIn && roleIn.value) || selectedRole || 'Kid Explorer'
      };
      if (!em || !pw) return alert('Enter email and password');
      MoneyMuncher.signUp(em, pw, profile).then(function(u) {
        account = { id: u.uid, email: u.email, name: profile.name, role: profile.role };
        saveSession(); sync();
        $('loginDialog').close();
        $('feedback').textContent = 'Account created! Cloud save active.';
        renderAccount(); renderStats(); renderMap();
      }).catch(function(e) { alert(e.message); });
    });
  }

  if (forgotPasswordBtn && emailIn) {
    forgotPasswordBtn.addEventListener('click', function() {
      var em = emailIn.value.trim();
      if (!em) return alert('Enter your email first, then tap Forgot password.');
      MoneyMuncher.resetPassword(em).then(function() {
        alert('Password reset email sent. Please check your inbox.');
      }).catch(function(e) { alert(e.message); });
    });
  }

  if (signInBtn && emailIn && passIn) {
    signInBtn.addEventListener('click', function() {
      var em = emailIn.value.trim(), pw = passIn.value;
      var signInName = nameIn && nameIn.value.trim();
      var profile = signInName ? { name: signInName, role: (roleIn && roleIn.value) || selectedRole } : null;
      if (!em || !pw) return alert('Enter email and password');
      MoneyMuncher.signIn(em, pw, profile).then(function(u) {
        var saved = (hasMM && MoneyMuncher.getUser && MoneyMuncher.getUser()) || {};
        account = {
          id: u.uid,
          email: u.email,
          name: (profile && profile.name) || saved.name || em.split('@')[0],
          role: (profile && profile.role) || saved.role || 'Player'
        };
        saveSession();
        $('loginDialog').close();
        $('feedback').textContent = 'Welcome back!';
        renderAccount(); renderStats(); renderMap();
      }).catch(function(e) { alert(e.message); });
    });
  }
});

// --- 7. Game functions ---
function clamp(n) { return Math.max(0, Math.round(n)); }
function levelAccessible(index) { return index <= progress.unlockedLevel; }

function renderStats() {
  $('coins').textContent   = clamp(state.coins);
  $('saved').textContent   = clamp(state.saved);
  $('joy').textContent     = clamp(state.joy);
  $('wisdom').textContent  = clamp(state.wisdom);
  $('badge').textContent    = state.wisdom >= 60 ? "Map Master"
                           : state.wisdom >= 40 ? "Coin Commander"
                           : state.wisdom >= 20 ? "Smart Saver"
                           : "Beginner Saver";
}

function renderAccount() {
  var loggedIn = Boolean(account.id) || (hasMM && MoneyMuncher.isLoggedIn());
  if (loggedIn && hasMM && MoneyMuncher.getUser && !account.id) {
    var user = MoneyMuncher.getUser();
    if (user) {
      account = {
        id: user.uid,
        email: user.email,
        name: user.name || (user.email ? user.email.split('@')[0] : 'Player'),
        role: user.role || 'Player'
      };
    }
  }
  $('accountStatus').textContent = loggedIn
    ? (account.name || 'Player') + (hasMM && MoneyMuncher.isLoggedIn() ? ' • cloud saved' : ' • local')
    : 'Guest explorer';
  $('loginOpenBtn').classList.toggle('hidden', loggedIn);
  $('logoutBtn').classList.toggle('hidden', !loggedIn);
}

function getSelectedMode() {
  selectedRole = normalizeRole(selectedRole);
  return experienceModes.find(function(mode) { return mode.id === selectedRole; }) || experienceModes[0];
}

function normalizeRole(role) {
  if (role === 'Kid') return 'Kid Explorer';
  if (role === 'Parent') return 'Parent Guide';
  if (role === 'Teacher') return 'Teacher Captain';
  return experienceModes.some(function(mode) { return mode.id === role; }) ? role : 'Kid Explorer';
}

function getSelectedAgePath() {
  return agePaths.find(function(path) { return path.id === selectedAgePath; }) || agePaths[0];
}

function renderPlaySetup() {
  var mode = getSelectedMode();
  $('experienceBadge').textContent = mode.badge;
  $('experienceHint').textContent = mode.hint;
  $('startBtn').textContent = mode.startLabel;

  var roleInput = $('roleInput');
  if (roleInput) roleInput.value = mode.id;

  var roleCards = $('roleCards');
  roleCards.innerHTML = '';
  experienceModes.forEach(function(item) {
    var card = document.createElement('button');
    card.type = 'button';
    card.className = 'role-card' + (item.id === selectedRole ? ' active' : '');
    card.innerHTML =
      '<span class="card-icon">' + item.icon + '</span>' +
      '<strong>' + item.title + '</strong>' +
      '<small>' + item.hint + '</small>';
    card.addEventListener('click', function() {
      selectedRole = item.id;
      localStorage.setItem('moneymuncherRole', selectedRole);
      if (account.name) {
        account.role = selectedRole;
        saveSession();
      }
      renderPlaySetup();
      renderMiniGames();
      renderAcademy();
    });
    roleCards.appendChild(card);
  });
}

function renderAgePaths() {
  var active = getSelectedAgePath();
  $('ageBadge').textContent = active.ages;

  var grid = $('agePathCards');
  grid.innerHTML = '';
  agePaths.forEach(function(path) {
    var card = document.createElement('button');
    card.type = 'button';
    card.className = 'age-card' + (path.id === selectedAgePath ? ' active' : '');
    card.innerHTML =
      '<span class="card-icon">' + path.icon + '</span>' +
      '<strong>' + path.name + '</strong>' +
      '<small>' + path.ages + ': ' + path.summary + '</small>' +
      '<div class="age-topics">' + path.topics.map(function(topic) { return '<span>' + topic + '</span>'; }).join('') + '</div>';
    card.addEventListener('click', function() {
      selectedAgePath = path.id;
      localStorage.setItem('moneymuncherAgePath', selectedAgePath);
      renderAgePaths();
      renderMiniGames();
      renderAcademy();
    });
    grid.appendChild(card);
  });
}

function renderMiniGames() {
  var mode = getSelectedMode();
  var path = getSelectedAgePath();
  $('miniGameBadge').textContent = mode.title + ' - ' + path.name;

  var grid = $('miniGameGrid');
  grid.innerHTML = '';
  var matches = miniGames.filter(function(game) {
    return game.audience.includes(mode.id) && game.ages.includes(path.id);
  });
  if (!matches.length) matches = miniGames.filter(function(game) { return game.audience.includes(mode.id); });
  if (!matches.length) matches = miniGames;

  matches.forEach(function(game) {
    var card = document.createElement('article');
    card.className = 'mini-game-card';
    card.innerHTML =
      '<span class="card-icon">' + game.icon + '</span>' +
      '<strong>' + game.title + '</strong>' +
      '<p>' + game.summary + '</p>' +
      '<div class="mini-game-meta"><span>' + game.duration + '</span><span>' + game.skill + '</span></div>' +
      '<button class="primary" type="button">Play mini-game</button>';
    card.querySelector('button').addEventListener('click', function() {
      if (game.href) {
        window.location.href = game.href;
        return;
      }
      if (game.levelIndex > progress.unlockedLevel) progress.unlockedLevel = game.levelIndex;
      startLevel(game.levelIndex);
    });
    grid.appendChild(card);
  });
}

function renderMap() {
  $('mapProgress').textContent = 'Level ' + Math.min(progress.unlockedLevel + 1, levels.length) + ' / ' + levels.length;
  $('mapPath').innerHTML = '';
  levels.forEach(function(level, index) {
    var complete = progress.completedLevels.includes(index);
    var unlocked = index <= progress.unlockedLevel;
    var node = document.createElement('article');
    node.className = 'level-node'
      + (complete ? ' complete' : '')
      + (state.currentLevel === index ? ' current' : '')
      + (!unlocked ? ' locked' : '');
    var action = !unlocked ? 'Locked' : complete ? 'Replay' : state.currentLevel === index ? 'Current' : 'Play';
    node.innerHTML =
      '<span>' + level.icon + '</span>' +
      '<strong>' + level.name + '</strong>' +
      '<small>' + level.skill + '</small>' +
      '<button class="' + (unlocked ? 'primary' : 'secondary') + '" ' + (!unlocked ? 'disabled' : '') + '>' + action + '</button>';
    node.querySelector('button').addEventListener('click', function() {
      if (unlocked) startLevel(index);
    });
    $('mapPath').appendChild(node);
  });
}

function renderScenario() {
  var level = levels[state.currentLevel];
  if (!level) return;
  $('levelEyebrow').textContent   = level.eyebrow;
  $('scenarioTitle').textContent  = level.title;
  $('scenarioText').textContent   = level.text;
  $('choices').innerHTML = '';
  level.choices.forEach(function(choice) {
    var btn = document.createElement('button');
    btn.className = 'choice';
    btn.innerHTML = '<strong>' + choice.label + '</strong><span>' + choice.detail + '</span>';
    btn.addEventListener('click', function() { choose(choice); });
    $('choices').appendChild(btn);
  });
}

function openDialog(id) {
  var d = $(id);
  if (typeof d.showModal === 'function') d.showModal();
  else d.classList.remove('hidden');
}

function startLevel(index) {
  if (!levelAccessible(index)) return;
  state.currentLevel = index;
  $('worldMap').classList.remove('hidden');
  $('game').classList.remove('hidden');
  sync();
  renderMap();
  renderScenario();
  $('game').scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function completeCurrentLevel() {
  if (!progress.completedLevels.includes(state.currentLevel)) {
    progress.completedLevels.push(state.currentLevel);
  }
  if (state.currentLevel === progress.unlockedLevel && progress.unlockedLevel < levels.length - 1) {
    progress.unlockedLevel += 1;
  }
  renderMap();
  sync();
}

function choose(choice) {
  state.coins  += choice.coins  || 0;
  state.saved  += choice.saved  || 0;
  state.joy    += choice.joy    || 0;
  state.wisdom += choice.wisdom || 0;

  $('feedback').textContent = choice.feedback;
  completeCurrentLevel();

  if (hasMM && MoneyMuncher.isLoggedIn()) {
    $('feedback').textContent += ' Cloud saved.';
  } else if (hasMM) {
    $('feedback').textContent += ' Saved on this device.';
  }

  renderStats();
  var next = state.currentLevel + 1;
  if (next < levels.length) {
    setTimeout(function() {
      $('feedback').textContent += ' Next unlocked: ' + levels[next].name + '. Open the map to continue.';
    }, 250);
  } else {
    setTimeout(function() {
      $('feedback').textContent += ' You finished the current Money World map!';
    }, 250);
  }
}

// --- 8. UI Event wiring ---
$('startBtn').addEventListener('click', function() { startLevel(progress.unlockedLevel); });

$('mapBtn').addEventListener('click', function() {
  $('worldMap').classList.remove('hidden');
  renderMap();
  $('worldMap').scrollIntoView({ behavior: 'smooth', block: 'start' });
});

$('teacherBtn').addEventListener('click', function() {
  $('hub').classList.remove('hidden');
  $('hub').scrollIntoView({ behavior: 'smooth', block: 'start' });
});

$('marketLabLoginBtn').addEventListener('click', function() {
  openDialog('loginDialog');
});

$('loginOpenBtn').addEventListener('click', function() { openDialog('loginDialog'); });

$('logoutBtn').addEventListener('click', function() {
  account = { id: "", email: "", name: "", role: "" };
  clearSession();
  if (hasMM) MoneyMuncher.signOut();
  renderAccount(); renderStats(); renderMap(); renderScenario();
});

// Original name/role form (local-only login)
$('loginForm').addEventListener('submit', function(ev) {
  ev.preventDefault();
  var name = $('nameInput').value.trim();
  var role = $('roleInput').value;
  var email = $('emailInput').value.trim();
  if (!name && !email) return;
  account = { id: 'local_' + Date.now(), email: email, name: name || email.split('@')[0], role: role };
  selectedRole = role;
  localStorage.setItem('moneymuncherRole', selectedRole);
  saveSession();
  $('loginDialog').close();
  $('feedback').textContent = 'Welcome, ' + account.name + '. Your progress is saved on this device.';
  renderAccount(); renderMap(); renderScenario();
});

$('questForm').addEventListener('submit', function(ev) {
  ev.preventDefault();
  var val = $('questInput').value.trim();
  if (!val) return;
  var li = document.createElement('li');
  li.textContent = 'Community quest idea: ' + val;
  $('questList').appendChild(li);
  $('questInput').value = '';
});

// --- 9. Boot ---
(function init() {
  restoreSession();
  loadFromManager();
  selectedRole = normalizeRole(account.role || selectedRole);
  localStorage.setItem('moneymuncherRole', selectedRole);
  renderPlaySetup();
  renderAgePaths();
  renderMiniGames();
  renderAccount();
  renderStats();
  renderMap();
  renderScenario();
})();

/* ==================== MONEYMUNCHER ACADEMY ==================== */

const lessons = [
  {
    id: "what-is-money",
    icon: "🪙",
    title: "What is Money?",
    kid: `
      <h3>Money is a Tool</h3>
      <p>Long ago, people traded chickens for bread. That was hard! What if the baker didn't want a chicken?</p>
      <p>So humans invented <strong>money</strong> — coins, paper, and now digital numbers on a screen. Money stores value. It is not good or evil; it is a tool, like a hammer or a pencil.</p>
      <ul>
        <li><strong>Coins & cash</strong> — you can hold them.</li>
        <li><strong>Digital money</strong> — numbers in an app or game.</li>
        <li><strong>Value</strong> — money only works because everyone agrees it has worth.</li>
      </ul>
      <p><em>MoneyMuncher wisdom:</em> Money is not love. Money is not happiness. Money is a tool you can learn to use well.</p>
    `,
    parent: `
      <h3>Teaching Kids About the Nature of Money</h3>
      <p>Abstract concepts like "digital money" can confuse children under 8. Use concrete examples:</p>
      <ul>
        <li><strong>Physical first:</strong> Start with real coins and cash before discussing cards/apps.</li>
        <li><strong>Trade stories:</strong> Explain bartering simply: "Imagine trading your toy for a sandwich. Money fixes that problem."</li>
        <li><strong>Emotional safety:</strong> Avoid saying "we can't afford it." Instead: "We choose to spend on X instead of Y today."</li>
      </ul>
      <p><strong>Conversation starter:</strong> Ask, "If money didn't exist, what would we use to trade?"</p>
    `,
    quiz: [
      { q: "Before money, people traded by:", options: ["Swimming", "Bartering (trading goods)", "Singing"], a: 1 },
      { q: "Money is best described as:", options: ["A magic spell", "A tool for storing value", "A type of food"], a: 1 },
      { q: "Digital money is:", options: ["Invisible coins in apps", "Chocolate coins", "Paper rain"], a: 0 }
    ]
  },
  {
    id: "needs-vs-wants",
    icon: "🍿",
    title: "Needs vs Wants",
    kid: `
      <h3>The Snack Shop Test</h3>
      <p><strong>Needs</strong> are things that keep you alive, safe, and healthy: water, food, sleep, a warm home, love.</p>
      <p><strong>Wants</strong> are things that are fun or nice: candy, the newest toy, extra video-game skins.</p>
      <p>Here is the tricky part: a <em>cookie</em> is a want, but <em>dinner</em> is a need. A <em>fancy bike</em> is a want, but <em>shoes that fit</em> are a need.</p>
      <p><strong>Power move:</strong> When you feel a strong "I WANT THIS NOW!" feeling, ask: "Will I be okay without it?" If yes, it is probably a want.</p>
    `,
    parent: `
      <h3>Needs vs Wants: Developmental Stages</h3>
      <p>Children naturally struggle with delayed gratification until roughly age 7–9. Your role is scaffolding, not shame.</p>
      <ul>
        <li><strong>Ages 4–6:</strong> Use visuals. Sort pictures into "Need/Want" baskets.</li>
        <li><strong>Ages 7–10:</strong> Introduce the 24-hour rule. If they still want it tomorrow, discuss budgeting.</li>
        <li><strong>Ages 11+:</strong> Let them experience mild regret. Natural consequences teach more than lectures.</li>
      </ul>
      <p><strong>Key phrase:</strong> "You can want something and still choose not to buy it. That choice is power."</p>
    `,
    quiz: [
      { q: "Which is a NEED?", options: ["Ice cream", "Water", "A toy car"], a: 1 },
      { q: "If you can survive without it, it is probably a:", options: ["Need", "Want", "Mystery"], a: 1 },
      { q: "Best response to 'I want candy now'?", options: ["Scream", "Ask: Is this a need or a want?", "Buy everything"], a: 1 }
    ]
  },
  {
    id: "saving-superpower",
    icon: "🏦",
    title: "Saving Superpower",
    kid: `
      <h3>Pay Your Future Self</h3>
      <p>Saving is like sending a gift to <strong>Future You</strong>. Future You will thank you when you have coins for that skateboard, game, or trip.</p>
      <p><strong>Three jars method:</strong></p>
      <ul>
        <li><strong>Spend jar</strong> — for today.</li>
        <li><strong>Save jar</strong> — for a goal.</li>
        <li><strong>Share jar</strong> — for helping others.</li>
      </ul>
      <p>Even saving <strong>1 coin</strong> starts the habit. Habits become character.</p>
    `,
    parent: `
      <h3>Building Saving Habits That Last</h3>
      <p>Saving is the strongest predictor of financial health in adulthood. Start early, start small.</p>
      <ul>
        <li><strong>Make it visible:</strong> Clear jars work better than apps for children under 10.</li>
        <li><strong>Set a match:</strong> Offer to double whatever they save toward a goal. This teaches compound interest simply.</li>
        <li><strong>Name the goal:</strong> "Red bike" beats "savings account" for motivation.</li>
      </ul>
      <p><strong>Research note:</strong> Kids who save for named goals by age 9 are 3x more likely to maintain emergency funds as adults.</p>
    `,
    quiz: [
      { q: "Saving is a gift to:", options: ["Your pet", "Future You", "A stranger"], a: 1 },
      { q: "The Three Jars are:", options: ["Spend, Save, Share", "Hide, Lose, Find", "Red, Blue, Green"], a: 0 },
      { q: "How much do you need to start saving?", options: ["100 coins", "1 coin", "0 coins"], a: 1 }
    ]
  },
  {
    id: "smart-spending",
    icon: "🛍️",
    title: "Smart Spending",
    kid: `
      <h3>The Detective Mindset</h3>
      <p>Before you buy, put on your <strong>Detective Hat</strong>. Smart spenders ask three questions:</p>
      <ul>
        <li><strong>1. Do I need it or want it?</strong></li>
        <li><strong>2. Is this the best price?</strong> Check two places.</li>
        <li><strong>3. Will I still want this in one week?</strong></li>
      </ul>
      <p>Comparing prices is like a treasure hunt. The prize is keeping more coins in your pocket for things you truly love.</p>
    `,
    parent: `
      <h3>Teaching Price Awareness & Impulse Control</h3>
      <p>Children are bombarded by "buy now" messaging. Build immunity through practice.</p>
      <ul>
        <li><strong>Grocery game:</strong> Give them $5 and a list. Let them choose brands and keep the change.</li>
        <li><strong>Online pause:</strong> Require a 2-day wait for any non-essential online purchase.</li>
        <li><strong>Unit-price math:</strong> "This bottle is $2 for 500ml. This one is $3 for 1L. Which is better?"</li>
      </ul>
      <p><strong>Parent tip:</strong> Never criticize a purchase after the fact. Discuss the decision process instead.</p>
    `,
    quiz: [
      { q: "A smart spender checks:", options: ["Prices", "The weather", "TV channels"], a: 0 },
      { q: "The 1-week test helps with:", options: ["Impulse control", "Sleeping", "Running"], a: 0 },
      { q: "Comparing prices is like:", options: ["A boring chore", "A treasure hunt", "A punishment"], a: 1 }
    ]
  },
  {
    id: "giving-sharing",
    icon: "🎁",
    title: "Giving & Sharing",
    kid: `
      <h3>Generosity is a Muscle</h3>
      <p>Giving money, time, or kindness makes your <strong>joy</strong> go up. Science proves it!</p>
      <p>But here is the secret: give <strong>sustainably</strong>. If you give away all your coins, you cannot help anyone tomorrow. The best helpers keep themselves healthy too.</p>
      <ul>
        <li><strong>Time</strong> — help a neighbor.</li>
        <li><strong>Talent</strong> — teach a friend a game.</li>
        <li><strong>Treasure</strong> — share a small amount.</li>
      </ul>
    `,
    parent: `
      <h3>Raising Generous, Not Guilty, Givers</h3>
      <p>Giving should feel empowering, not obligatory. Avoid forced charity; instead, connect giving to values.</p>
      <ul>
        <li><strong>Let them choose the cause:</strong> Animal shelters often resonate more than abstract charities.</li>
        <li><strong>Match donations:</strong> "For every dollar you give, I will give two."</li>
        <li><strong>Time + money:</strong> Combine a small donation with volunteer work so they see impact.</li>
      </ul>
      <p><strong>Watch for:</strong> Children who give everything away to gain approval. Teach sustainable generosity: "Keep your jar full so you can give again next month."</p>
    `,
    quiz: [
      { q: "Giving sustainably means:", options: ["Giving everything", "Keeping enough to give again later", "Never giving"], a: 1 },
      { q: "Three things you can give:", options: ["Time, Talent, Treasure", "Naps, Yawns, Pizza", "Rocks, Sand, Water"], a: 0 },
      { q: "Generosity makes your ____ go up.", options: ["Joy", "Shoes", "Hair"], a: 0 }
    ]
  },
  {
    id: "family-budgets",
    icon: "🏡",
    title: "Family Budgets",
    kid: `
      <h3>Money is a Team Sport</h3>
      <p>A <strong>budget</strong> is just a plan for your money. Families who plan together fight less and smile more.</p>
      <p>Try the <strong>Pizza Budget</strong> trick:</p>
      <ul>
        <li>The crust = needs (home, food, school).</li>
        <li>The cheese = fun (games, movies, snacks).</li>
        <li>The toppings = saving & giving.</li>
      </ul>
      <p>Every family member can help. Even kids can count coins or suggest free fun activities.</p>
    `,
    parent: `
      <h3>Family Financial Meetings That Work</h3>
      <p>Include children in age-appropriate budgeting conversations. Transparency reduces anxiety.</p>
      <ul>
        <li><strong>Ages 5–8:</strong> Use envelope systems. "This envelope is for groceries. When it is empty, we wait."</li>
        <li><strong>Ages 9–12:</strong> Share a simple spreadsheet. Let them see how small daily costs add up.</li>
        <li><strong>Ages 13+:</strong> Give a monthly clothing/entertainment allowance. No bailouts. Natural consequences build responsibility.</li>
      </ul>
      <p><strong>Family meeting format (15 min):</strong> Win of the week → Upcoming expense → Kid suggestion → Close with gratitude.</p>
    `,
    quiz: [
      { q: "A budget is:", options: ["A plan for money", "A type of bird", "A magic spell"], a: 0 },
      { q: "In the Pizza Budget, the crust is:", options: ["Needs", "Fun stuff", "Toppings"], a: 0 },
      { q: "Who can help with family money planning?", options: ["Only parents", "Everyone in the family", "Only pets"], a: 1 }
    ]
  }
];

// --- Academy State ---
let academyMode = 'kid'; // 'kid' or 'parent'
let currentLessonId = null;

function lessonMatchesAge(lesson) {
  var byPath = {
    'coin-collectors': ['what-is-money', 'needs-vs-wants', 'saving-superpower', 'giving-sharing', 'family-budgets'],
    'budget-builders': ['what-is-money', 'needs-vs-wants', 'saving-superpower', 'smart-spending', 'giving-sharing', 'family-budgets'],
    'money-masters': ['saving-superpower', 'smart-spending', 'family-budgets']
  };
  return (byPath[selectedAgePath] || byPath['coin-collectors']).includes(lesson.id);
}

function renderAcademy() {
  var completed = hasMM ? (MoneyMuncher.get().completedLessons || []) : [];
  var grid = $('lessonGrid');
  var reader = $('lessonReader');
  var path = getSelectedAgePath();
  grid.classList.remove('hidden');
  reader.classList.add('hidden');

  grid.innerHTML = '';
  lessons.filter(lessonMatchesAge).forEach(function(lesson) {
    var isDone = completed.includes(lesson.id);
    var card = document.createElement('article');
    card.className = 'lesson-card' + (isDone ? ' completed' : '');
    card.innerHTML =
      (isDone ? '<span class="lesson-badge-earned">✓ Done</span>' : '') +
      '<span class="lesson-icon">' + lesson.icon + '</span>' +
      '<h4>' + lesson.title + '</h4>' +
      '<small>' + path.name + ' - ' + (isDone ? 'Completed +5 wisdom' : 'Tap to read') + '</small>' +
      '<div class="lesson-progress"><div style="width:' + (isDone ? 100 : 0) + '%"></div></div>';
    card.addEventListener('click', function() { openLesson(lesson.id); });
    grid.appendChild(card);
  });
}

function openLesson(id) {
  var lesson = lessons.find(function(l) { return l.id === id; });
  if (!lesson) return;
  currentLessonId = id;

  $('lessonGrid').classList.add('hidden');
  $('lessonReader').classList.remove('hidden');
  $('quizBox').classList.add('hidden');
  $('quizResult').textContent = '';

  updateLessonContent();
}

function updateLessonContent() {
  var lesson = lessons.find(function(l) { return l.id === currentLessonId; });
  var html = '<h2>' + lesson.icon + ' ' + lesson.title + '</h2>';
  html += (academyMode === 'parent' ? lesson.parent : lesson.kid);
  $('lessonContent').innerHTML = html;

  // Show quiz only in kid mode (or both if you prefer)
  $('quizBox').classList.remove('hidden');
  renderQuiz(lesson.quiz);
}

function renderQuiz(questions) {
  var box = $('quizQuestions');
  box.innerHTML = '';
  questions.forEach(function(q, idx) {
    var div = document.createElement('div');
    div.className = 'quiz-question';
    div.innerHTML = '<strong>Q' + (idx + 1) + '. ' + q.q + '</strong>';
    q.options.forEach(function(opt, oIdx) {
      var label = document.createElement('label');
      label.innerHTML = '<input type="radio" name="q' + idx + '" value="' + oIdx + '"> ' + opt;
      div.appendChild(label);
    });
    box.appendChild(div);
  });
}

function checkQuiz() {
  var lesson = lessons.find(function(l) { return l.id === currentLessonId; });
  var correct = 0;
  lesson.quiz.forEach(function(q, idx) {
    var picked = document.querySelector('input[name="q' + idx + '"]:checked');
    if (picked && parseInt(picked.value) === q.a) correct++;
  });

  var result = $('quizResult');
  var perfect = correct === lesson.quiz.length;

  if (perfect) {
    result.textContent = '🎉 Perfect! +' + (5 + 10) + ' Wisdom and a Money Scholar point!';
    result.className = 'quiz-result perfect';
  } else {
    result.textContent = '⭐ ' + correct + '/' + lesson.quiz.length + ' correct. Read again and retry!';
    result.className = 'quiz-result good';
  }

  // Record completion
  if (correct >= 2) { // 2/3 or 3/3 to pass
    completeLesson(currentLessonId, perfect ? 15 : 5);
  }
}

function completeLesson(id, wisdomGain) {
  if (!hasMM) return;
  var p = MoneyMuncher.get();
  var completed = Array.isArray(p.completedLessons) ? p.completedLessons : [];
  if (completed.includes(id)) return; // already done

  completed.push(id);
  MoneyMuncher.set({
    completedLessons: completed,
    wisdom: (p.wisdom || 0) + wisdomGain
  });
  MoneyMuncher.addBadge('money-scholar');

  // Refresh UI so the grid shows "Done"
  setTimeout(renderAcademy, 800);
}

// --- Academy Controls ---
$('academyBtn').addEventListener('click', function() {
  $('academy').classList.remove('hidden');
  renderAcademy();
  $('academy').scrollIntoView({ behavior: 'smooth' });
});

$('academyKidMode').addEventListener('click', function() {
  academyMode = 'kid';
  $('academyKidMode').classList.add('active', 'primary'); $('academyKidMode').classList.remove('secondary');
  $('academyParentMode').classList.remove('active', 'primary'); $('academyParentMode').classList.add('secondary');
  $('academy').classList.remove('parent-mode');
  if (currentLessonId) updateLessonContent();
});

$('academyParentMode').addEventListener('click', function() {
  academyMode = 'parent';
  $('academyParentMode').classList.add('active', 'primary'); $('academyParentMode').classList.remove('secondary');
  $('academyKidMode').classList.remove('active', 'primary'); $('academyKidMode').classList.add('secondary');
  $('academy').classList.add('parent-mode');
  if (currentLessonId) updateLessonContent();
});

$('closeLessonBtn').addEventListener('click', function() {
  currentLessonId = null;
  renderAcademy();
});

$('submitQuizBtn').addEventListener('click', checkQuiz);
