/* ============================================================
   MoneyMuncher Game Logic
   Reads/writes through MoneyMuncher (Firebase + localStorage).
   ============================================================ */

// --- 0. Helpers ---
function $(id) { return document.getElementById(id); }

var pageParams = new URLSearchParams(window.location.search);
var isIOSAppExperience = pageParams.get('source') === 'ios-app';
if (isIOSAppExperience) document.documentElement.classList.add('ios-app');

function canOpenNativeFamilyQuest() {
  return Boolean(
    isIOSAppExperience &&
    window.webkit &&
    window.webkit.messageHandlers &&
    window.webkit.messageHandlers.moneyMuncher
  );
}

function openNativeFamilyQuest() {
  if (!canOpenNativeFamilyQuest()) return false;
  window.webkit.messageHandlers.moneyMuncher.postMessage({ type: 'open-family-quest' });
  return true;
}

function safeStorageGet(key, fallback) {
  try {
    var value = localStorage.getItem(key);
    return value === null ? fallback : value;
  } catch (error) {
    console.warn('[MM] Local storage read failed for ' + key, error);
    return fallback;
  }
}

function safeStorageSet(key, value) {
  try {
    localStorage.setItem(key, value);
    return true;
  } catch (error) {
    console.warn('[MM] Local storage write failed for ' + key, error);
    return false;
  }
}

function safeStorageRemove(key) {
  try {
    localStorage.removeItem(key);
    return true;
  } catch (error) {
    console.warn('[MM] Local storage removal failed for ' + key, error);
    return false;
  }
}

function safeStorageJson(key, fallback) {
  try {
    return JSON.parse(safeStorageGet(key, JSON.stringify(fallback)));
  } catch (error) {
    console.warn('[MM] Local storage JSON was invalid for ' + key, error);
    return fallback;
  }
}

const hasMM = typeof window.MoneyMuncher !== 'undefined';

// --- 1. Data ---
const defaultState = { coins: 30, saved: 0, joy: 50, wisdom: 0, currentLevel: 0 };
let state   = { ...defaultState };
let progress = { unlockedLevel: 0, completedLevels: [] };
let account = { id: "", name: "", role: "" };
let selectedRole = safeStorageGet('moneymuncherRole', 'Kid Explorer') || 'Kid Explorer';
let selectedAgePath = safeStorageGet('moneymuncherAgePath', 'coin-collectors') || 'coin-collectors';
let activeGeneratedQuest = null;
let generatedQuestHistory = loadGeneratedQuestHistory();
let currentGeneratedQuest = generatedQuestHistory[0] || null;
let betaSignupIntent = false;

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

const questContextTemplates = {
  grocery: {
    icon: 'GQ',
    label: 'Groceries',
    name: 'Grocery Quest',
    skill: 'Budget choices',
    example: 'Buying snacks for a road trip',
    title: function() { return 'Build a snack plan'; },
    text: function(moment, coins) {
      return 'Your family is thinking about "' + moment + '". You have ' + coins + ' quest coins. What plan keeps today fun and leaves room for later?';
    },
    prompt: function() { return 'Which choice gave us fun today and choices tomorrow?'; },
    choices: function(coins) {
      return [
        { label: 'Make a mini list', detail: 'Pick favorites before spending.', coins: -scaledCoins(coins, .45, 6), saved: scaledCoins(coins, .2, 3), joy: 9, wisdom: 18, feedback: 'A list turns a store moment into a plan. You kept the fun and protected the coins.' },
        { label: 'Grab every treat', detail: 'Maximum fun, fast coin drain.', coins: -scaledCoins(coins, .9, 12), saved: 0, joy: 17, wisdom: 5, feedback: 'Big treat energy is real. Now the budget has less space for the next family want.' },
        { label: 'One treat, one swap', detail: 'Choose a favorite and a smarter buy.', coins: -scaledCoins(coins, .6, 8), saved: scaledCoins(coins, .15, 2), joy: 13, wisdom: 16, feedback: 'Nice balance. A smart swap keeps the favorite without letting the budget get munched.' }
      ];
    }
  },
  toy: {
    icon: 'TQ',
    label: 'Toy',
    name: 'Toy Quest',
    skill: 'Impulse control',
    example: 'Choosing whether to buy a new game',
    title: function() { return 'The want-it-now test'; },
    text: function(moment, coins) {
      return 'A tempting choice shows up: "' + moment + '". You have ' + coins + ' quest coins. What should Future You think about first?';
    },
    prompt: function() { return 'Would this still feel exciting next week?'; },
    choices: function(coins) {
      return [
        { label: 'Wait one day', detail: 'Let the want cool down.', coins: 0, saved: scaledCoins(coins, .25, 4), joy: -1, wisdom: 20, feedback: 'Waiting is a quiet superpower. Some wants shrink when they get a little space.' },
        { label: 'Buy it right now', detail: 'Fast joy, fewer options later.', coins: -scaledCoins(coins, .85, 10), saved: 0, joy: 18, wisdom: 5, feedback: 'Instant joy can be fun. The learning is noticing which future goal moved farther away.' },
        { label: 'Compare first', detail: 'Check price, use, and timing.', coins: -scaledCoins(coins, .55, 7), saved: scaledCoins(coins, .18, 3), joy: 11, wisdom: 17, feedback: 'Detective move. Comparing gives your brain time to catch up with your excitement.' }
      ];
    }
  },
  allowance: {
    icon: 'AQ',
    label: 'Allowance',
    name: 'Allowance Quest',
    skill: 'Spend-save-share',
    example: 'Deciding what to do with chore money',
    title: function() { return 'New coins, new choices'; },
    text: function(moment, coins) {
      return 'New coins arrive from "' + moment + '". You have ' + coins + ' quest coins. How should they split between now, later, and kindness?';
    },
    prompt: function() { return 'What would you put in Spend, Save, and Share jars?'; },
    choices: function(coins) {
      return [
        { label: 'Use three jars', detail: 'Spend, save, and share.', coins: -scaledCoins(coins, .35, 5), saved: scaledCoins(coins, .35, 5), joy: 12, wisdom: 19, feedback: 'Three-jar thinking is strong. You gave every coin a job instead of letting it wander.' },
        { label: 'Spend it all', detail: 'All fun, no future plan.', coins: -scaledCoins(coins, .95, 12), saved: 0, joy: 18, wisdom: 5, feedback: 'All-spend choices can feel exciting. The question is whether Future You still gets a vote.' },
        { label: 'Name one goal', detail: 'Save for something specific.', coins: -scaledCoins(coins, .25, 4), saved: scaledCoins(coins, .5, 8), joy: 7, wisdom: 18, feedback: 'Named goals are powerful. Saving for a real thing feels much easier than saving for nothing.' }
      ];
    }
  },
  birthday: {
    icon: 'BQ',
    label: 'Birthday',
    name: 'Birthday Quest',
    skill: 'Planning ahead',
    example: 'Planning a birthday gift budget',
    title: function() { return 'The celebration budget'; },
    text: function(moment, coins) {
      return 'A celebration is coming: "' + moment + '". You have ' + coins + ' quest coins for the plan. How can you make it thoughtful without overspending?';
    },
    prompt: function() { return 'What part of a gift makes someone feel cared for besides the price?'; },
    choices: function(coins) {
      return [
        { label: 'Plan the budget', detail: 'Gift, card, and coins left over.', coins: -scaledCoins(coins, .5, 7), saved: scaledCoins(coins, .2, 3), joy: 13, wisdom: 18, feedback: 'Thoughtful and planned. A budget can make a celebration calmer, not smaller.' },
        { label: 'Buy the flashiest gift', detail: 'Big wow, tight coins.', coins: -scaledCoins(coins, .95, 12), saved: 0, joy: 17, wisdom: 6, feedback: 'A flashy gift can sparkle, but price is only one kind of caring.' },
        { label: 'Make part of it', detail: 'Mix creativity with spending.', coins: -scaledCoins(coins, .35, 5), saved: scaledCoins(coins, .3, 4), joy: 15, wisdom: 17, feedback: 'Creative spending unlocked. Time, care, and coins can work together.' }
      ];
    }
  },
  trip: {
    icon: 'FQ',
    label: 'Family Trip',
    name: 'Trip Quest',
    skill: 'Tradeoffs',
    example: 'Choosing road trip treats and souvenirs',
    title: function() { return 'The trip tradeoff'; },
    text: function(moment, coins) {
      return 'Your family is planning "' + moment + '". You have ' + coins + ' quest coins. What choice makes the trip fun without eating the whole budget?';
    },
    prompt: function() { return 'Which trip memory matters more than buying something?'; },
    choices: function(coins) {
      return [
        { label: 'Pick a trip budget', detail: 'Fun money with a clear limit.', coins: -scaledCoins(coins, .5, 8), saved: scaledCoins(coins, .22, 3), joy: 14, wisdom: 18, feedback: 'A trip budget is freedom with guardrails. Everyone knows where the coins can go.' },
        { label: 'Buy at every stop', detail: 'Many treats, money fades.', coins: -scaledCoins(coins, .9, 12), saved: 0, joy: 18, wisdom: 5, feedback: 'Every-stop spending feels fun until the bigger choice disappears.' },
        { label: 'Choose one memory item', detail: 'One buy, more room for experiences.', coins: -scaledCoins(coins, .4, 6), saved: scaledCoins(coins, .25, 4), joy: 13, wisdom: 17, feedback: 'Strong travel choice. A single memory item can mean more than a bag of random stuff.' }
      ];
    }
  },
  giving: {
    icon: 'SQ',
    label: 'Sharing',
    name: 'Sharing Quest',
    skill: 'Generosity',
    example: 'Helping a fundraiser while saving for a goal',
    title: function() { return 'The generous choice'; },
    text: function(moment, coins) {
      return 'A kindness moment appears: "' + moment + '". You have ' + coins + ' quest coins. How can you help and keep your own plan healthy?';
    },
    prompt: function() { return 'How can we be generous in money, time, or effort?'; },
    choices: function(coins) {
      return [
        { label: 'Give a little', detail: 'Kind and sustainable.', coins: -scaledCoins(coins, .25, 4), saved: scaledCoins(coins, .15, 2), joy: 14, wisdom: 17, feedback: 'Sustainable generosity keeps your heart open and your plan steady.' },
        { label: 'Give everything', detail: 'Huge heart, empty jar.', coins: -scaledCoins(coins, .9, 12), saved: 0, joy: 18, wisdom: 7, feedback: 'That is a kind heart. The next lesson is keeping enough strength to help again later.' },
        { label: 'Give time too', detail: 'Money is not the only help.', coins: -scaledCoins(coins, .15, 2), saved: scaledCoins(coins, .2, 3), joy: 15, wisdom: 19, feedback: 'Beautiful. Time and effort can be just as valuable as coins.' }
      ];
    }
  },
  subscription: {
    icon: 'SQ',
    label: 'Subscription',
    name: 'Subscription Quest',
    skill: 'Recurring costs',
    example: 'A free app trial is about to renew',
    title: function() { return 'The sneaky monthly bite'; },
    text: function(moment, coins) {
      return 'A recurring cost shows up: "' + moment + '". You have ' + coins + ' quest coins. What keeps tiny charges from munching a big goal?';
    },
    prompt: function() { return 'What reminders or rules help us notice recurring costs?'; },
    choices: function(coins) {
      return [
        { label: 'Check the renewal', detail: 'Know the date and cost.', coins: 0, saved: scaledCoins(coins, .25, 4), joy: 4, wisdom: 20, feedback: 'Sharp eye. Recurring costs are easier to handle when they stop being invisible.' },
        { label: 'Ignore it', detail: 'Small charge, repeated bite.', coins: -scaledCoins(coins, .35, 5), saved: 0, joy: -2, wisdom: 5, feedback: 'That little charge can become a big bite over time. A reminder would protect the goal.' },
        { label: 'Ask if it earns a spot', detail: 'Keep it only if it is worth it.', coins: -scaledCoins(coins, .2, 3), saved: scaledCoins(coins, .2, 3), joy: 8, wisdom: 17, feedback: 'Good value check. Every subscription should earn its place again and again.' }
      ];
    }
  }
};

const surpriseQuestMoments = [
  { context: 'grocery', prompt: 'Picking snacks for a family movie night' },
  { context: 'toy', prompt: 'Choosing whether to buy a shiny toy today' },
  { context: 'allowance', prompt: 'Splitting allowance after finishing weekend chores' },
  { context: 'birthday', prompt: 'Planning a birthday gift for a friend' },
  { context: 'trip', prompt: 'Choosing souvenirs during a family day trip' },
  { context: 'giving', prompt: 'Helping a school fundraiser' },
  { context: 'subscription', prompt: 'A free app trial is about to renew' }
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
  var sess = safeStorageJson('moneymuncherSession', null);
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
function saveSession()  { safeStorageSet('moneymuncherSession', JSON.stringify(account)); }
function clearSession() { safeStorageRemove('moneymuncherSession'); }
function restoreSession() {
  var s = safeStorageJson('moneymuncherSession', null);
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
  var authStatus = $('authFormStatus');
  var authTitle  = $('authDialogTitle');
  var authCopy   = $('authDialogCopy');
  var nameField  = $('authNameField');
  var roleField  = $('authRoleField');

  function setAuthStatus(message) {
    authStatus.textContent = message || '';
    authStatus.classList.toggle('visible', Boolean(message));
    if (message) {
      requestAnimationFrame(function() {
        authStatus.scrollIntoView({ block: 'nearest' });
      });
    }
  }

  function setAuthBusy(busy, action) {
    signUpBtn.disabled = busy;
    signInBtn.disabled = busy;
    forgotPasswordBtn.disabled = busy;
    signInBtn.textContent = busy && action === 'signin' ? 'Signing in…' : 'Sign In';
    signUpBtn.textContent = busy && action === 'signup' ? 'Creating account…' : 'Sign Up';
  }

  function authErrorMessage(error) {
    var code = error && error.code ? error.code : '';
    if (code === 'auth/user-not-found' || code === 'auth/wrong-password' || code === 'auth/invalid-login-credentials' || code === 'auth/invalid-credential') {
      return 'The email or password is incorrect.';
    }
    if (code === 'auth/network-request-failed' || code === 'auth/timeout') {
      return 'Sign in could not reach the account service. Check the internet connection and try again.';
    }
    if (code === 'auth/too-many-requests') {
      return 'Too many attempts. Wait a moment, then try again or reset the password.';
    }
    return error && error.message ? error.message : 'The account request failed. Please try again.';
  }

  // Native iOS "Family Sign Up" links here with action=signup. Open the
  // account dialog immediately so reviewers do not have to find Log in first.
  var requestedAction = pageParams.get('action');
  if (requestedAction === 'signup' || requestedAction === 'signin') {
    if (requestedAction === 'signup') {
      selectedRole = 'Family Team';
      safeStorageSet('moneymuncherRole', selectedRole);
      if (roleIn) roleIn.value = selectedRole;
    } else {
      if (authTitle) authTitle.textContent = 'Sign in to Money Muncher';
      if (authCopy) authCopy.textContent = 'Enter the family review account email and password.';
      if (nameField) nameField.classList.add('hidden');
      if (roleField) roleField.classList.add('hidden');
      if (signUpBtn) signUpBtn.hidden = true;
    }
    setTimeout(function() {
      openDialog('loginDialog');
      if (requestedAction === 'signin') setAuthStatus('Enter the review account email and password, then tap Sign In.');
      var firstField = requestedAction === 'signin' ? emailIn : nameIn;
      if (firstField && window.matchMedia && window.matchMedia('(pointer: fine)').matches) firstField.focus();
    }, 0);
  }

  if (roleIn) {
    roleIn.value = selectedRole;
    roleIn.addEventListener('change', function() {
      selectedRole = roleIn.value;
      safeStorageSet('moneymuncherRole', selectedRole);
      renderPlaySetup();
      renderMiniGames();
      renderQuestGeneratorBadge();
    });
  }

  if (signUpBtn && emailIn && passIn) {
    signUpBtn.addEventListener('click', function() {
      var em = emailIn.value.trim(), pw = passIn.value;
      var profile = {
        name: (nameIn && nameIn.value.trim()) || em.split('@')[0],
        role: (roleIn && roleIn.value) || selectedRole || 'Kid Explorer',
        betaInterest: betaSignupIntent,
        signupSource: betaSignupIntent ? 'ios-beta-banner' : 'homepage-account',
        platformInterest: betaSignupIntent ? 'ios' : '',
        betaJoinedAt: betaSignupIntent ? new Date().toISOString() : ''
      };
      if (!em || !pw) {
        setAuthStatus('Enter both an email address and password.');
        (!em ? emailIn : passIn).focus();
        return;
      }
      setAuthStatus('Creating your account…');
      setAuthBusy(true, 'signup');
      MoneyMuncher.signUp(em, pw, profile).then(function(u) {
        account = {
          id: u.uid,
          email: u.email,
          emailVerified: Boolean(u.emailVerified),
          name: profile.name,
          role: profile.role,
          betaInterest: profile.betaInterest,
          signupSource: profile.signupSource,
          platformInterest: profile.platformInterest,
          betaJoinedAt: profile.betaJoinedAt
        };
        saveSession(); sync();
        $('loginDialog').close();
        $('feedback').textContent = u.verificationSent
          ? 'Account created. Check ' + u.email + ' for the verification link.'
          : 'Account created, but the verification email could not be sent. Use Resend verification.';
        $('verificationEmail').textContent = u.email;
        $('verificationDialogStatus').textContent = u.verificationSent
          ? 'Verification email sent. Check your inbox and spam folder.'
          : 'Email was not sent. Tap Resend email to try again.';
        openDialog('emailVerificationDialog');
        betaSignupIntent = false;
        renderAccount(); renderStats(); renderMap();
      }).catch(function(e) {
        setAuthStatus(authErrorMessage(e));
      }).finally(function() {
        setAuthBusy(false);
      });
    });
  }

  if (forgotPasswordBtn && emailIn) {
    forgotPasswordBtn.addEventListener('click', function() {
      var em = emailIn.value.trim();
      if (!em) {
        setAuthStatus('Enter your email first, then tap Forgot password.');
        emailIn.focus();
        return;
      }
      setAuthStatus('Sending password-reset email…');
      setAuthBusy(true, 'reset');
      MoneyMuncher.resetPassword(em).then(function() {
        setAuthStatus('Password-reset email sent to ' + em + '. Check your inbox and spam folder.');
      }).catch(function(e) {
        setAuthStatus(authErrorMessage(e));
      }).finally(function() {
        setAuthBusy(false);
      });
    });
  }

  if (signInBtn && emailIn && passIn) {
    signInBtn.addEventListener('click', function() {
      var em = emailIn.value.trim(), pw = passIn.value;
      var signInName = nameIn && nameIn.value.trim();
      var profile = signInName || betaSignupIntent ? {
        name: signInName || '',
        role: (roleIn && roleIn.value) || selectedRole,
        betaInterest: betaSignupIntent,
        signupSource: betaSignupIntent ? 'ios-beta-banner' : '',
        platformInterest: betaSignupIntent ? 'ios' : '',
        betaJoinedAt: betaSignupIntent ? new Date().toISOString() : ''
      } : null;
      if (!em || !pw) {
        setAuthStatus('Enter both an email address and password.');
        (!em ? emailIn : passIn).focus();
        return;
      }
      if (!hasMM || typeof MoneyMuncher.signIn !== 'function') {
        setAuthStatus('The account service is still loading. Check the internet connection and try again.');
        return;
      }
      setAuthStatus('Signing in securely…');
      setAuthBusy(true, 'signin');
      MoneyMuncher.signIn(em, pw, profile).then(function(u) {
        var saved = (hasMM && MoneyMuncher.getUser && MoneyMuncher.getUser()) || {};
        account = {
          id: u.uid,
          email: u.email,
          emailVerified: Boolean(u.emailVerified),
          name: (profile && profile.name) || saved.name || em.split('@')[0],
          role: (profile && profile.role) || saved.role || 'Player',
          betaInterest: (profile && profile.betaInterest) || saved.betaInterest || false,
          signupSource: (profile && profile.signupSource) || saved.signupSource || '',
          platformInterest: (profile && profile.platformInterest) || saved.platformInterest || '',
          betaJoinedAt: (profile && profile.betaJoinedAt) || saved.betaJoinedAt || ''
        };
        saveSession();
        $('loginDialog').close();
        $('feedback').textContent = !u.emailVerified
          ? 'Welcome back. Please verify ' + u.email + '.'
          : (betaSignupIntent ? 'Thanks. Your account is marked for iOS beta interest.' : 'Welcome back!');
        betaSignupIntent = false;
        renderAccount(); renderStats(); renderMap();
      }).catch(function(e) {
        setAuthStatus(authErrorMessage(e));
      }).finally(function() {
        setAuthBusy(false);
      });
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
  $('badge').textContent    = activeGeneratedQuest ? "Everyday Quest"
                           : state.wisdom >= 60 ? "Map Master"
                           : state.wisdom >= 40 ? "Coin Commander"
                           : state.wisdom >= 20 ? "Smart Saver"
                           : "Beginner Saver";
}

function renderAccount() {
  var loggedIn = Boolean(account.id) || (hasMM && MoneyMuncher.isLoggedIn());
  if (loggedIn && hasMM && MoneyMuncher.getUser) {
    var user = MoneyMuncher.getUser();
    if (user) {
      account = {
        id: user.uid,
        email: user.email,
        emailVerified: Boolean(user.emailVerified),
        name: user.name || (user.email ? user.email.split('@')[0] : 'Player'),
        role: user.role || 'Player'
      };
    }
  }
  var cloudLoggedIn = hasMM && MoneyMuncher.isLoggedIn();
  $('accountStatus').textContent = loggedIn
    ? (account.name || 'Player') + (cloudLoggedIn
      ? (account.emailVerified ? ' • email verified' : ' • verify ' + (account.email || 'email'))
      : ' • local')
    : 'Guest explorer';
  $('loginOpenBtn').classList.toggle('hidden', loggedIn);
  $('resendVerificationBtn').classList.toggle('hidden', !cloudLoggedIn || account.emailVerified);
  $('refreshVerificationBtn').classList.toggle('hidden', !cloudLoggedIn || account.emailVerified);
  $('logoutBtn').classList.toggle('hidden', !loggedIn);
  $('deleteAccountOpenBtn').classList.toggle('hidden', !loggedIn || !cloudLoggedIn);
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
      safeStorageSet('moneymuncherRole', selectedRole);
      if (account.name) {
        account.role = selectedRole;
        saveSession();
      }
      renderPlaySetup();
      renderMiniGames();
      renderAcademy();
      renderQuestGeneratorBadge();
    });
    roleCards.appendChild(card);
  });
  renderQuestGeneratorBadge();
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
      safeStorageSet('moneymuncherAgePath', selectedAgePath);
      renderAgePaths();
      renderMiniGames();
      renderAcademy();
      renderQuestGeneratorBadge();
    });
    grid.appendChild(card);
  });
  renderQuestGeneratorBadge();
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

function renderQuestGeneratorBadge() {
  var badge = $('questGeneratorBadge');
  if (!badge) return;
  badge.textContent = getSelectedMode().title + ' - ' + getSelectedAgePath().ages;
}

function scaledCoins(coins, ratio, minimum) {
  return Math.min(coins, Math.max(minimum, Math.round(coins * ratio)));
}

function loadGeneratedQuestHistory() {
  try {
    var saved = safeStorageJson('moneymuncherGeneratedQuests', []);
    if (!Array.isArray(saved)) return [];
    return saved.filter(isGeneratedQuest).slice(0, 6);
  } catch (e) {
    return [];
  }
}

function isGeneratedQuest(quest) {
  return Boolean(
    quest &&
    typeof quest.title === 'string' &&
    typeof quest.text === 'string' &&
    Array.isArray(quest.choices) &&
    quest.choices.length === 3
  );
}

function saveGeneratedQuestHistory() {
  safeStorageSet('moneymuncherGeneratedQuests', JSON.stringify(generatedQuestHistory.slice(0, 6)));
}

function getQuestCoinBudget() {
  var input = $('generatorCoins');
  var value = input ? parseInt(input.value, 10) : 30;
  if (!Number.isFinite(value)) value = 30;
  value = Math.min(100, Math.max(5, Math.round(value / 5) * 5));
  if (input) input.value = value;
  return value;
}

function inferQuestContext(prompt, selectedContext) {
  if (selectedContext && selectedContext !== 'auto' && questContextTemplates[selectedContext]) {
    return selectedContext;
  }

  var text = (prompt || '').toLowerCase();
  var keywordGroups = [
    { id: 'subscription', words: ['subscription', 'trial', 'renew', 'monthly', 'app', 'streaming'] },
    { id: 'birthday', words: ['birthday', 'gift', 'party', 'present', 'celebration'] },
    { id: 'trip', words: ['trip', 'travel', 'vacation', 'road', 'souvenir', 'airport'] },
    { id: 'giving', words: ['donate', 'fundraiser', 'charity', 'help', 'share', 'giving'] },
    { id: 'allowance', words: ['allowance', 'chore', 'earned', 'paid', 'payday', 'income'] },
    { id: 'toy', words: ['toy', 'game', 'lego', 'skin', 'robux', 'book', 'bike'] },
    { id: 'grocery', words: ['grocery', 'snack', 'food', 'meal', 'dinner', 'lunch', 'store', 'treat'] }
  ];

  for (var i = 0; i < keywordGroups.length; i++) {
    if (keywordGroups[i].words.some(function(word) { return text.includes(word); })) {
      return keywordGroups[i].id;
    }
  }

  return 'grocery';
}

function normalizeQuestMoment(prompt, contextId) {
  var template = questContextTemplates[contextId] || questContextTemplates.grocery;
  var moment = (prompt || '').trim().replace(/\s+/g, ' ');
  if (!moment) moment = template.example;
  if (moment.length > 160) moment = moment.slice(0, 157) + '...';
  return moment;
}

function makeGeneratedQuest(prompt, selectedContext, coins) {
  var contextId = inferQuestContext(prompt, selectedContext);
  var template = questContextTemplates[contextId] || questContextTemplates.grocery;
  var moment = normalizeQuestMoment(prompt, contextId);
  var path = getSelectedAgePath();
  var mode = getSelectedMode();

  return {
    id: 'everyday-' + Date.now(),
    generated: true,
    createdAt: new Date().toISOString(),
    icon: template.icon,
    name: template.name,
    skill: template.skill,
    eyebrow: 'Everyday Quest: ' + template.label,
    title: template.title(moment, coins, path, mode),
    text: template.text(moment, coins, path, mode),
    parentPrompt: template.prompt(moment, path, mode),
    choices: template.choices(coins, path, mode)
  };
}

function storeGeneratedQuest(quest) {
  generatedQuestHistory = [quest].concat(generatedQuestHistory.filter(function(item) {
    return item.id !== quest.id;
  })).slice(0, 6);
  saveGeneratedQuestHistory();
  renderGeneratedQuestHistory();
}

function renderGeneratedQuest(quest) {
  if (!isGeneratedQuest(quest)) return;
  currentGeneratedQuest = quest;

  $('generatedQuestCard').classList.remove('hidden');
  $('generatedQuestIcon').textContent = quest.icon || 'EQ';
  $('generatedQuestSkill').textContent = quest.skill || 'Money choices';
  $('generatedQuestTitle').textContent = quest.title;
  $('generatedQuestText').textContent = quest.text;
  $('generatedQuestPrompt').textContent = 'Family talk: ' + (quest.parentPrompt || 'What felt smart, tempting, or kind?');

  var choices = $('generatedQuestChoices');
  choices.innerHTML = '';
  quest.choices.forEach(function(choice) {
    var item = document.createElement('div');
    item.className = 'generated-choice';

    var title = document.createElement('strong');
    title.textContent = choice.label;

    var detail = document.createElement('span');
    detail.textContent = choice.detail;

    item.appendChild(title);
    item.appendChild(detail);
    choices.appendChild(item);
  });

  $('playGeneratedQuestBtn').onclick = function() {
    startGeneratedQuest(quest);
  };
}

function renderGeneratedQuestHistory() {
  var list = $('generatedQuestHistory');
  if (!list) return;
  list.innerHTML = '';

  if (!generatedQuestHistory.length) {
    var empty = document.createElement('p');
    empty.className = 'history-empty';
    empty.textContent = 'No family quests yet.';
    list.appendChild(empty);
    return;
  }

  generatedQuestHistory.forEach(function(quest) {
    var card = document.createElement('article');
    card.className = 'history-card';

    var title = document.createElement('strong');
    title.textContent = quest.title;

    var detail = document.createElement('span');
    detail.textContent = quest.skill + ' - ' + quest.name;

    var replay = document.createElement('button');
    replay.type = 'button';
    replay.className = 'secondary small';
    replay.textContent = 'Replay';
    replay.addEventListener('click', function() {
      renderGeneratedQuest(quest);
      startGeneratedQuest(quest);
    });

    card.appendChild(title);
    card.appendChild(detail);
    card.appendChild(replay);
    list.appendChild(card);
  });
}

function generateQuestFromForm() {
  var prompt = $('generatorPrompt').value;
  var context = $('generatorContext').value;
  var quest = makeGeneratedQuest(prompt, context, getQuestCoinBudget());
  renderGeneratedQuest(quest);
  storeGeneratedQuest(quest);
  return quest;
}

function startGeneratedQuest(quest) {
  if (!isGeneratedQuest(quest)) return;
  activeGeneratedQuest = quest;
  $('worldMap').classList.add('hidden');
  $('game').classList.remove('hidden');
  $('feedback').textContent = 'Pick a choice together. Every choice teaches something.';
  renderStats();
  renderScenario();
  $('game').scrollIntoView({ behavior: 'smooth', block: 'start' });
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
  var level = activeGeneratedQuest || levels[state.currentLevel];
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
  if (!d || d.open) return Boolean(d);
  if (typeof d.showModal === 'function') {
    try {
      d.showModal();
      return true;
    } catch (error) {
      console.warn('[MM] Native dialog presentation failed for ' + id, error);
    }
  }
  d.classList.remove('hidden');
  d.setAttribute('open', '');
  return true;
}

function startLevel(index) {
  if (!levelAccessible(index)) return;
  activeGeneratedQuest = null;
  state.currentLevel = index;
  $('worldMap').classList.remove('hidden');
  $('game').classList.remove('hidden');
  sync();
  renderStats();
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

  if (activeGeneratedQuest) {
    $('feedback').textContent += ' Family talk: ' + (activeGeneratedQuest.parentPrompt || 'What felt smart, tempting, or kind?');
    if (hasMM && MoneyMuncher.isLoggedIn()) {
      $('feedback').textContent += ' Cloud saved.';
    } else if (hasMM) {
      $('feedback').textContent += ' Saved on this device.';
    }
    sync();
    renderStats();
    return;
  }

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

$('generatorBtn').addEventListener('click', function() {
  $('questGenerator').scrollIntoView({ behavior: 'smooth', block: 'start' });
});

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

var verificationResendPending = false;

function resendVerification(statusElement, button) {
  if (verificationResendPending) return Promise.resolve();
  verificationResendPending = true;
  if (button) button.disabled = true;
  statusElement.textContent = 'Sending verification email…';
  return MoneyMuncher.resendEmailVerification().then(function(result) {
    statusElement.textContent = result.alreadyVerified
      ? 'This email is already verified.'
      : 'Verification email sent to ' + result.email + '. Check your inbox and spam folder.';
    renderAccount();
  }).catch(function(error) {
    statusElement.textContent = 'Verification email failed: ' + (error.message || 'Please try again.');
  }).finally(function() {
    // Prevent accidental rapid retries and Firebase rate-limit errors.
    setTimeout(function() {
      verificationResendPending = false;
      if (button) button.disabled = false;
    }, 15000);
  });
}

$('resendVerificationBtn').addEventListener('click', function() {
  $('verificationEmail').textContent = account.email || '';
  $('verificationDialogStatus').textContent = '';
  openDialog('emailVerificationDialog');
  resendVerification($('verificationDialogStatus'), $('verificationDialogResendBtn'));
});

$('verificationDialogResendBtn').addEventListener('click', function() {
  resendVerification($('verificationDialogStatus'), $('verificationDialogResendBtn'));
});

var continueToFamilyQuestBtn = $('continueToFamilyQuestBtn');
if (continueToFamilyQuestBtn && canOpenNativeFamilyQuest()) {
  continueToFamilyQuestBtn.hidden = false;
  continueToFamilyQuestBtn.addEventListener('click', function() {
    openNativeFamilyQuest();
  });
}

function quietlyRefreshVerification() {
  if (!(hasMM && MoneyMuncher.isLoggedIn()) || account.emailVerified) return;
  MoneyMuncher.refreshEmailVerification().then(function(result) {
    account.emailVerified = result.emailVerified;
    if (result.emailVerified) {
      $('feedback').textContent = 'Email verified. Thank you!';
      renderAccount();
    }
  }).catch(function() {});
}

document.addEventListener('visibilitychange', function() {
  if (document.visibilityState === 'visible') quietlyRefreshVerification();
});
window.addEventListener('pageshow', quietlyRefreshVerification);

$('refreshVerificationBtn').addEventListener('click', function() {
  var button = $('refreshVerificationBtn');
  button.disabled = true;
  button.textContent = 'Checking…';
  MoneyMuncher.refreshEmailVerification().then(function(result) {
    account.emailVerified = result.emailVerified;
    $('feedback').textContent = result.emailVerified
      ? 'Email verified. Thank you!'
      : 'Email is not verified yet. Open the link sent to ' + result.email + ', then try again.';
    renderAccount();
  }).catch(function(error) {
    $('feedback').textContent = 'Could not refresh verification: ' + (error.message || 'Please try again.');
  }).finally(function() {
    button.disabled = false;
    button.textContent = "I've verified";
  });
});

$('logoutBtn').addEventListener('click', function() {
  account = { id: "", email: "", name: "", role: "" };
  clearSession();
  if (hasMM) MoneyMuncher.signOut();
  renderAccount(); renderStats(); renderMap(); renderScenario();
});

$('deleteAccountOpenBtn').addEventListener('click', function() {
  $('deleteAccountStatus').textContent = '';
  openDialog('deleteAccountDialog');
});

$('confirmDeleteAccountBtn').addEventListener('click', function() {
  var button = $('confirmDeleteAccountBtn');
  var status = $('deleteAccountStatus');
  button.disabled = true;
  status.textContent = 'Deleting account and cloud data…';

  MoneyMuncher.deleteAccount(function(message) {
    status.textContent = message;
  }).then(function() {
    account = { id: "", email: "", name: "", role: "" };
    clearSession();
    state = { ...defaultState };
    progress = { unlockedLevel: 0, completedLevels: [] };
    loadFromManager();
    $('deleteAccountDialog').close();
    $('feedback').textContent = 'Your account and cloud-saved data were permanently deleted.';
    renderAccount(); renderStats(); renderMap(); renderScenario();
  }).catch(function(error) {
    status.textContent = error && error.code === 'auth/requires-recent-login'
      ? 'For security, sign out, sign in again, and then retry account deletion.'
      : 'Account deletion failed: ' + (error.message || 'Please try again.');
  }).finally(function() {
    button.disabled = false;
  });
});

// Treat Return/Go from the iOS keyboard as Sign In. Account creation remains
// an explicit choice, preventing existing users from receiving an ambiguous
// email-already-in-use error when they press Return on iPad.
$('loginForm').addEventListener('submit', function(ev) {
  ev.preventDefault();
  if (!$('signInBtn').disabled) $('signInBtn').click();
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

$('generatorForm').addEventListener('submit', function(ev) {
  ev.preventDefault();
  generateQuestFromForm();
});

$('surpriseQuestBtn').addEventListener('click', function() {
  var sample = surpriseQuestMoments[Math.floor(Math.random() * surpriseQuestMoments.length)];
  $('generatorPrompt').value = sample.prompt;
  $('generatorContext').value = sample.context;
  generateQuestFromForm();
});

$('clearGeneratedQuestsBtn').addEventListener('click', function() {
  generatedQuestHistory = [];
  currentGeneratedQuest = null;
  saveGeneratedQuestHistory();
  renderGeneratedQuestHistory();
  $('generatedQuestCard').classList.add('hidden');
});

// --- 9. Boot ---
(function init() {
  restoreSession();
  loadFromManager();
  selectedRole = normalizeRole(account.role || selectedRole);
  safeStorageSet('moneymuncherRole', selectedRole);
  renderPlaySetup();
  renderAgePaths();
  renderMiniGames();
  renderQuestGeneratorBadge();
  renderGeneratedQuestHistory();
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
