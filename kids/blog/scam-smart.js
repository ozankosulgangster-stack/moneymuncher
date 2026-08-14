(function () {
  const body = document.body;
  const sections = Array.from(document.querySelectorAll("[data-focus-section]"));
  const focusToggle = document.querySelector("#focusModeToggle");
  const focusToolbar = document.querySelector("#focusToolbar");
  const focusProgress = document.querySelector("#focusProgress");
  const previousButton = document.querySelector("#focusPreviousBtn");
  const nextButton = document.querySelector("#focusNextBtn");
  const readButton = document.querySelector("#readKeyStepsBtn");
  const copyStatus = document.querySelector("#copyStatus");
  let focusIndex = 0;
  let statusTimer = null;

  focusToggle.addEventListener("click", () => {
    const enabled = !body.classList.contains("focus-mode");
    body.classList.toggle("focus-mode", enabled);
    focusToggle.setAttribute("aria-pressed", String(enabled));
    focusToggle.textContent = enabled ? "Exit focus mode" : "Turn on focus mode";
    focusToolbar.hidden = !enabled;
    if (enabled) showFocusSection(focusIndex, true);
    else sections.forEach((section) => section.classList.remove("is-focused"));
  });

  previousButton.addEventListener("click", () => showFocusSection(focusIndex - 1, true));
  nextButton.addEventListener("click", () => showFocusSection(focusIndex + 1, true));

  function showFocusSection(index, moveFocus) {
    focusIndex = Math.max(0, Math.min(sections.length - 1, index));
    sections.forEach((section, sectionIndex) => section.classList.toggle("is-focused", sectionIndex === focusIndex));
    focusProgress.textContent = "Step " + (focusIndex + 1) + " of " + sections.length;
    previousButton.disabled = focusIndex === 0;
    nextButton.disabled = focusIndex === sections.length - 1;
    nextButton.textContent = focusIndex === sections.length - 1 ? "Last step" : "Next";
    if (moveFocus) sections[focusIndex].focus({ preventScroll: true });
    const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    sections[focusIndex].scrollIntoView({ behavior: prefersReducedMotion ? "auto" : "smooth", block: "start" });
  }

  document.querySelectorAll("[data-copy-target]").forEach((button) => {
    button.addEventListener("click", async () => {
      const target = document.getElementById(button.dataset.copyTarget);
      if (!target) return;
      const text = target.textContent.trim().replace(/^[“\"]|[”\"]$/g, "");
      try {
        await navigator.clipboard.writeText(text);
        announce("Copied. You can paste it where you need it.");
      } catch (error) {
        announce("Select the phrase and use your device’s copy command.");
      }
    });
  });

  readButton.addEventListener("click", () => {
    if (!("speechSynthesis" in window)) {
      announce("Read aloud is not supported in this browser.");
      return;
    }
    if (window.speechSynthesis.speaking) {
      window.speechSynthesis.cancel();
      readButton.textContent = "Read key steps aloud";
      return;
    }
    const speech = new SpeechSynthesisUtterance(
      "Stop. Do not reply, click, or pay. Check. Could this message be fake or rushed? Tell. Show a trusted adult. You can say: I don't send money, gift cards, or codes. I'm blocking this and telling my grown-up now."
    );
    speech.rate = 0.85;
    speech.onend = () => { readButton.textContent = "Read key steps aloud"; };
    speech.onerror = () => { readButton.textContent = "Read key steps aloud"; };
    readButton.textContent = "Stop reading";
    window.speechSynthesis.speak(speech);
  });

  document.querySelector("#printScamGuideBtn").addEventListener("click", () => window.print());

  function announce(message) {
    window.clearTimeout(statusTimer);
    copyStatus.textContent = message;
    copyStatus.classList.add("show");
    statusTimer = window.setTimeout(() => copyStatus.classList.remove("show"), 2600);
  }
})();
