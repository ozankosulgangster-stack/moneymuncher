const lessons = {
  loyalty: {
    eyebrow: "Chapter 1 · Rewards",
    title: "Star Market",
    subtitle: "Luma Fox and the loyalty-card puzzle",
    emoji: "🛍️",
    character: "Luma Fox",
    characterEmoji: "🦊",
    story: "At Star Market, Luma stamps a loyalty card when Munch shops. Ten stamps earn a free berry bowl—but a shop across the path sells the same berries for 4 fewer coins.",
    factTitle: "A loyalty card is a rewards tracker",
    factText: "It may give points, stamps, or discounts. It does not borrow money. Compare the real price, and ask a grown-up what information the program collects.",
    question: "What should Munch compare first?",
    answers: [
      ["The final price", "Check what the berries cost after any reward", true],
      ["The shiniest card", "A fancy design does not make a better deal", false],
      ["Points only", "Points can hide a higher price", false]
    ],
    correct: "Exactly. A reward is useful only when the whole deal still makes sense.",
    retry: "Good try. Start with the final price; points are only one part of the deal."
  },
  credit: {
    eyebrow: "Chapter 2 · Borrowing",
    title: "Cloud Castle",
    subtitle: "Captain Credit and the promise to repay",
    emoji: "🏰",
    character: "Captain Credit",
    characterEmoji: "🦉",
    story: "At Cloud Castle, Captain Credit lends Munch 30 coins for a kite. The card works now, but a bill arrives later. Those 30 coins were borrowed—not a gift.",
    factTitle: "A credit card is a borrowing tool",
    factText: "The bank pays the shop, then the cardholder must repay the bank. A credit limit is the most that can be borrowed, not extra money to spend.",
    question: "The 30-coin bill is due Friday. What is the safest plan?",
    answers: [
      ["Pay all 30 on time", "That avoids carrying the balance forward", true],
      ["Forget the bill", "Late payments can add costs", false],
      ["Borrow 30 more", "New borrowing does not erase the first bill", false]
    ],
    correct: "That’s the card-smart move. Paying the full bill on time avoids carrying this balance forward.",
    retry: "Good try. Borrowed coins still belong on the bill, so paying the full amount on time is safest."
  },
  interest: {
    eyebrow: "Chapter 3 · Rates",
    title: "Percent Peak",
    subtitle: "Professor Percent and the growing balance",
    emoji: "⛰️",
    character: "Professor Percent",
    characterEmoji: "🐢",
    story: "On Percent Peak, a 100-coin balance waits for one year. The sign says 20% yearly interest. Professor Percent shows Munch that 20% of 100 is 20.",
    factTitle: "Interest is a price or a reward",
    factText: "When money is borrowed, interest is the extra cost. When money is saved, interest can help it grow. The rate tells how quickly that amount changes.",
    question: "If nothing is paid, what could the 100-coin balance become after one year?",
    answers: [
      ["120 coins", "100 borrowed + 20 interest", true],
      ["100 coins", "That leaves out the interest", false],
      ["20 coins", "That is only the interest amount", false]
    ],
    correct: "Right! Twenty percent of 100 is 20, so 100 + 20 becomes 120 coins.",
    retry: "Good try. Add the 20-coin interest charge to the original 100-coin balance."
  }
};

const order = ["loyalty", "credit", "interest"];
const storageKey = "moneyMuncherCardQuest";
let completed = readProgress();
let activeStop = null;

const worldScreen = document.getElementById("worldScreen");
const storyScreen = document.getElementById("storyScreen");
const endingScreen = document.getElementById("endingScreen");
const feedback = document.getElementById("feedback");
const collectStar = document.getElementById("collectStar");

function readProgress() {
  try {
    const value = JSON.parse(localStorage.getItem(storageKey));
    return Array.isArray(value) ? value.filter((item) => order.includes(item)) : [];
  } catch {
    return [];
  }
}

function saveProgress() {
  localStorage.setItem(storageKey, JSON.stringify(completed));
}

function showOnly(screen) {
  [worldScreen, storyScreen, endingScreen].forEach((item) => {
    item.hidden = item !== screen;
    item.classList.remove("is-arriving");
  });
  screen.classList.add("is-arriving");
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function refreshMap() {
  document.getElementById("starCount").textContent = completed.length + " / 3";

  document.querySelectorAll(".world-stop").forEach((button, index) => {
    const id = button.dataset.stop;
    const isComplete = completed.includes(id);
    const unlocked = index === 0 || completed.includes(order[index - 1]);
    button.disabled = !unlocked;
    button.classList.toggle("complete", isComplete);
    const state = button.querySelector(".stop-state");
    state.textContent = isComplete ? "Replay ✓" : unlocked ? "Start →" : "Locked";
  });

  const moonBank = document.getElementById("moonBank");
  moonBank.disabled = completed.length !== order.length;
  moonBank.querySelector("small").textContent = completed.length === order.length ? "Enter the finale" : "Collect " + (3 - completed.length) + " more";

  const status = document.getElementById("mapStatus");
  if (completed.length === 0) status.textContent = "Begin at Star Market. Each story opens the next path.";
  else if (completed.length < 3) status.textContent = "Wonderful! " + (3 - completed.length) + " story " + (3 - completed.length === 1 ? "star remains." : "stars remain.");
  else status.textContent = "The Moon Bank is glowing. Your final badge is ready!";
}

function openLesson(id) {
  const lesson = lessons[id];
  if (!lesson) return;
  activeStop = id;

  document.getElementById("storyEyebrow").textContent = lesson.eyebrow;
  document.getElementById("storyTitle").textContent = lesson.title;
  document.getElementById("storySubtitle").textContent = lesson.subtitle;
  document.getElementById("sceneEmoji").textContent = lesson.emoji;
  document.getElementById("characterEmoji").textContent = lesson.characterEmoji;
  document.getElementById("characterName").textContent = lesson.character;
  document.getElementById("storyText").textContent = lesson.story;
  document.getElementById("factTitle").textContent = lesson.factTitle;
  document.getElementById("factText").textContent = lesson.factText;
  document.getElementById("questionTitle").textContent = lesson.question;

  const sceneCard = document.getElementById("sceneCard");
  sceneCard.className = "scene-card " + id;
  const choices = document.getElementById("choices");
  choices.innerHTML = "";

  lesson.answers.forEach((answer, index) => {
    const button = document.createElement("button");
    button.className = "choice";
    button.type = "button";
    button.innerHTML = '<span class="choice-icon" aria-hidden="true">' + (index + 1) + '</span><span><strong></strong><small></small></span>';
    button.querySelector("strong").textContent = answer[0];
    button.querySelector("small").textContent = answer[1];
    button.addEventListener("click", () => answerQuestion(index));
    choices.appendChild(button);
  });

  feedback.hidden = true;
  feedback.className = "feedback";
  collectStar.hidden = true;
  showOnly(storyScreen);
  document.getElementById("storyTitle").focus({ preventScroll: true });
}

function answerQuestion(selectedIndex) {
  const lesson = lessons[activeStop];
  const buttons = [...document.querySelectorAll(".choice")];
  buttons.forEach((button, index) => {
    button.disabled = true;
    if (lesson.answers[index][2]) {
      button.classList.add("correct");
      button.querySelector(".choice-icon").textContent = "✓";
    }
    if (index === selectedIndex) {
      button.classList.add("selected");
      if (!lesson.answers[index][2]) button.querySelector(".choice-icon").textContent = "×";
    }
  });

  const correct = lesson.answers[selectedIndex][2];
  feedback.textContent = correct ? lesson.correct : lesson.retry;
  feedback.classList.toggle("try-again", !correct);
  feedback.hidden = false;
  collectStar.hidden = false;
  collectStar.focus({ preventScroll: true });
}

function completeLesson() {
  if (!activeStop) return;
  if (!completed.includes(activeStop)) completed.push(activeStop);
  completed = order.filter((id) => completed.includes(id));
  saveProgress();
  refreshMap();
  showOnly(worldScreen);
  const nextIndex = Math.min(completed.length, order.length - 1);
  const nextButton = document.querySelector('[data-stop="' + order[nextIndex] + '"]');
  if (nextButton) nextButton.focus({ preventScroll: true });
}

document.querySelectorAll(".world-stop").forEach((button) => {
  button.addEventListener("click", () => openLesson(button.dataset.stop));
});

document.getElementById("backToMap").addEventListener("click", () => {
  refreshMap();
  showOnly(worldScreen);
});

collectStar.addEventListener("click", completeLesson);

document.getElementById("moonBank").addEventListener("click", () => {
  if (completed.length === order.length) showOnly(endingScreen);
});

document.getElementById("playAgain").addEventListener("click", () => {
  completed = [];
  activeStop = null;
  saveProgress();
  refreshMap();
  showOnly(worldScreen);
  document.querySelector('[data-stop="loyalty"]').focus({ preventScroll: true });
});

refreshMap();
