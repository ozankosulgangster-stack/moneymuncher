(() => {
  const params = new URLSearchParams(window.location.search);
  const campaignContext = {
    source: params.get("utm_source") || "direct",
    medium: params.get("utm_medium") || "none",
    campaign: params.get("utm_campaign") || "none",
    content: params.get("utm_content") || "none",
    google_click_id: params.get("gclid") || "none",
    reddit_click_id: params.get("rdt_cid") || "none"
  };

  try {
    sessionStorage.setItem("moneymuncher_campaign", JSON.stringify(campaignContext));
  } catch {
    // Campaign measurement should never block the page experience.
  }

  const track = (name, details = {}) => {
    const payload = { ...campaignContext, ...details };

    if (typeof window.gtag === "function") {
      window.gtag("event", name, payload);
    }

    if (Array.isArray(window.dataLayer)) {
      window.dataLayer.push({ event: `mm_${name}`, ...payload });
    }
  };

  track("campaign_landing_view", { page_variant: "parent_quest_v1" });

  const questSection = document.getElementById("family-quest");
  const questCard = document.getElementById("questCard");
  const result = document.getElementById("questResult");
  const resultTitle = document.getElementById("resultTitle");
  const resultCopy = document.getElementById("resultCopy");
  const startQuestCta = document.getElementById("startQuestCta");
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  let questStarted = false;
  let questCompleted = false;

  const trackQuestStart = (entryMethod) => {
    if (questStarted) return;
    questStarted = true;
    track("family_quest_start", {
      quest_id: "twenty_dollar_decision",
      entry_method: entryMethod
    });
  };

  startQuestCta?.addEventListener("click", () => {
    trackQuestStart("hero_cta");
  });

  const responses = {
    spend: {
      title: "Spending brings something good today.",
      copy: "The trade-off is that the soccer-ball goal stays where it is. That does not make the choice bad—it makes tomorrow part of the decision."
    },
    save: {
      title: "Saving moves a future goal closer.",
      copy: "The trade-off is waiting for the game. Naming what the wait is for can make saving feel like progress instead of punishment."
    },
    split: {
      title: "One amount can do more than one job.",
      copy: "Splitting the money can balance today, tomorrow, and someone else—but every part moves more slowly. The useful skill is choosing the split on purpose."
    }
  };

  document.querySelectorAll("[data-choice]").forEach((button) => {
    button.addEventListener("click", () => {
      const choice = button.dataset.choice;
      const response = responses[choice];
      if (!response || questCompleted) return;

      trackQuestStart("choice");
      questCompleted = true;

      resultTitle.textContent = response.title;
      resultCopy.textContent = response.copy;
      questCard.hidden = true;
      result.hidden = false;
      result.focus({ preventScroll: true });
      result.scrollIntoView({ behavior: reduceMotion ? "auto" : "smooth", block: "center" });

      track("family_quest_complete", {
        quest_id: "twenty_dollar_decision",
        quest_choice: choice,
        page_variant: "parent_quest_v1"
      });
    });
  });

  document.querySelectorAll(".app-store-link").forEach((link) => {
    link.addEventListener("click", () => {
      track("app_store_click", {
        cta_location: link.dataset.ctaLocation || "unknown",
        page_variant: "parent_quest_v1"
      });
    });
  });

  if (window.location.hash === "#family-quest") {
    trackQuestStart("deep_link");
    questSection?.scrollIntoView({ block: "start" });
  }
})();
