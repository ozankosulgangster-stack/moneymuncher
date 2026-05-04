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
  }
];

// --- 6. Auth wiring (only attaches if buttons exist) ---
document.addEventListener('DOMContentLoaded', function() {
  var signUpBtn  = $('signUpBtn');
  var signInBtn  = $('signInBtn');
  var emailIn    = $('emailInput');
  var passIn     = $('passInput');

  if (signUpBtn && emailIn && passIn) {
    signUpBtn.addEventListener('click', function() {
      var em = emailIn.value.trim(), pw = passIn.value;
      if (!em || !pw) return alert('Enter email and password');
      MoneyMuncher.signUp(em, pw).then(function(u) {
        account = { id: u.uid, name: em.split('@')[0], role: 'Player' };
        saveSession(); sync();
        $('loginDialog').close();
        $('feedback').textContent = 'Account created! Cloud save active.';
        renderAccount(); renderStats(); renderMap();
      }).catch(function(e) { alert(e.message); });
    });
  }

  if (signInBtn && emailIn && passIn) {
    signInBtn.addEventListener('click', function() {
      var em = emailIn.value.trim(), pw = passIn.value;
      if (!em || !pw) return alert('Enter email and password');
      MoneyMuncher.signIn(em, pw).then(function(u) {
        account = { id: u.uid, name: em.split('@')[0], role: 'Player' };
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
  $('accountStatus').textContent = loggedIn
    ? (account.name || 'Player') + (hasMM && MoneyMuncher.isLoggedIn() ? ' • cloud saved' : ' • local')
    : 'Guest explorer';
  $('loginOpenBtn').classList.toggle('hidden', loggedIn);
  $('logoutBtn').classList.toggle('hidden', !loggedIn);
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

$('loginOpenBtn').addEventListener('click', function() { openDialog('loginDialog'); });

$('logoutBtn').addEventListener('click', function() {
  account = { id: "", name: "", role: "" };
  clearSession();
  if (hasMM) MoneyMuncher.signOut();
  renderAccount(); renderStats(); renderMap(); renderScenario();
});

// Original name/role form (local-only login)
$('loginForm').addEventListener('submit', function(ev) {
  ev.preventDefault();
  var name = $('nameInput').value.trim();
  var role = $('roleInput').value;
  if (!name) return;
  account = { id: 'local_' + Date.now(), name: name, role: role };
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
  renderAccount();
  renderStats();
  renderMap();
  renderScenario();
})();
