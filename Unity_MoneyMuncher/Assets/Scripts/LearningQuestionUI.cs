using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class LearningQuestionUI : MonoBehaviour
{
    public GameObject panel;
    public Text questionLabel;
    public Text feedbackLabel;
    public Button[] answerButtons;
    public Text[] answerLabels;

    private LearningQuestionGate activeGate;

    private void Awake()
    {
        ResolveReferences();

        if (answerButtons == null || answerButtons.Length == 0)
        {
            Debug.LogError(
                "LearningQuestionUI could not find any answer buttons. " +
                "Rebuild the Learning Trail scene before publishing WebGL.",
                this);
            Hide();
            return;
        }

        for (int i = 0; i < answerButtons.Length; i++)
        {
            Button button = answerButtons[i];
            if (button == null)
            {
                Debug.LogWarning($"LearningQuestionUI answer button {i} is not assigned.", this);
                continue;
            }

            int answerIndex = i;
            button.onClick.AddListener(() => ChooseAnswer(answerIndex));
        }

        Hide();
    }

    public void Show(LearningQuestionGate gate)
    {
        if (gate == null)
        {
            Debug.LogWarning("LearningQuestionUI was asked to show a missing question gate.", this);
            Hide();
            return;
        }

        ResolveReferences();
        activeGate = gate;

        if (panel != null)
        {
            panel.SetActive(true);
        }

        if (questionLabel != null)
        {
            questionLabel.text = gate.question;
        }

        if (feedbackLabel != null)
        {
            feedbackLabel.text = "";
        }

        int buttonCount = answerButtons == null ? 0 : answerButtons.Length;

        for (int i = 0; i < buttonCount; i++)
        {
            Button button = answerButtons[i];
            if (button == null)
            {
                continue;
            }

            bool hasAnswer = gate.answers != null && i < gate.answers.Length && !string.IsNullOrEmpty(gate.answers[i]);
            button.gameObject.SetActive(hasAnswer);
            button.interactable = hasAnswer;

            if (hasAnswer && answerLabels != null && i < answerLabels.Length && answerLabels[i] != null)
            {
                answerLabels[i].text = gate.answers[i];
            }
        }
    }

    private void ChooseAnswer(int answerIndex)
    {
        if (activeGate == null)
        {
            return;
        }

        bool correct = activeGate.IsCorrect(answerIndex);
        activeGate.Answer(answerIndex);

        if (feedbackLabel != null)
        {
            feedbackLabel.text = correct
                ? $"Correct! {activeGate.explanation}"
                : $"Try again. {activeGate.explanation}";
        }

        if (correct)
        {
            SetButtonsInteractable(false);
            StartCoroutine(HideAfterDelay());
        }
    }

    private IEnumerator HideAfterDelay()
    {
        yield return new WaitForSeconds(1.2f);
        Hide();
    }

    private void SetButtonsInteractable(bool interactable)
    {
        if (answerButtons == null)
        {
            return;
        }

        foreach (Button button in answerButtons)
        {
            if (button != null)
            {
                button.interactable = interactable;
            }
        }
    }

    public bool HasValidReferences(out string issue)
    {
        ResolveReferences();

        if (panel == null)
        {
            issue = "Question Panel is not assigned.";
            return false;
        }

        if (questionLabel == null || feedbackLabel == null)
        {
            issue = "Question Text or Feedback Text is not assigned.";
            return false;
        }

        if (answerButtons == null || answerButtons.Length == 0)
        {
            issue = "No answer buttons are assigned.";
            return false;
        }

        for (int i = 0; i < answerButtons.Length; i++)
        {
            if (answerButtons[i] == null)
            {
                issue = $"Answer button {i + 1} is not assigned.";
                return false;
            }

            if (answerLabels == null || i >= answerLabels.Length || answerLabels[i] == null)
            {
                issue = $"Answer label {i + 1} is not assigned.";
                return false;
            }
        }

        issue = "";
        return true;
    }

    private void ResolveReferences()
    {
        if (panel == null)
        {
            Transform panelTransform = transform.Find("Question Panel");
            if (panelTransform != null)
            {
                panel = panelTransform.gameObject;
            }
        }

        if (panel == null)
        {
            return;
        }

        bool hasMissingButton = answerButtons == null || answerButtons.Length == 0;
        if (!hasMissingButton)
        {
            foreach (Button button in answerButtons)
            {
                if (button == null)
                {
                    hasMissingButton = true;
                    break;
                }
            }
        }

        if (hasMissingButton)
        {
            Button[] discoveredButtons = panel.GetComponentsInChildren<Button>(true);
            if (discoveredButtons.Length > 0)
            {
                answerButtons = discoveredButtons;
            }
        }

        if (questionLabel == null || feedbackLabel == null)
        {
            Text[] labels = panel.GetComponentsInChildren<Text>(true);
            foreach (Text label in labels)
            {
                if (label == null)
                {
                    continue;
                }

                if (questionLabel == null && label.gameObject.name == "Question Text")
                {
                    questionLabel = label;
                }
                else if (feedbackLabel == null && label.gameObject.name == "Feedback Text")
                {
                    feedbackLabel = label;
                }
            }
        }

        int buttonCount = answerButtons == null ? 0 : answerButtons.Length;
        bool hasMissingLabel = answerLabels == null || answerLabels.Length != buttonCount;
        if (!hasMissingLabel)
        {
            foreach (Text label in answerLabels)
            {
                if (label == null)
                {
                    hasMissingLabel = true;
                    break;
                }
            }
        }

        if (hasMissingLabel)
        {
            Text[] resolvedLabels = new Text[buttonCount];

            for (int i = 0; i < buttonCount; i++)
            {
                if (answerLabels != null && i < answerLabels.Length && answerLabels[i] != null)
                {
                    resolvedLabels[i] = answerLabels[i];
                }
                else if (answerButtons[i] != null)
                {
                    resolvedLabels[i] = answerButtons[i].GetComponentInChildren<Text>(true);
                }
            }

            answerLabels = resolvedLabels;
        }
    }

    public void Hide()
    {
        activeGate = null;

        if (panel != null)
        {
            panel.SetActive(false);
        }
    }
}
