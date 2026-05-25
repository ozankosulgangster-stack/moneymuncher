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
        for (int i = 0; i < answerButtons.Length; i++)
        {
            int answerIndex = i;
            answerButtons[i].onClick.AddListener(() => ChooseAnswer(answerIndex));
        }

        Hide();
    }

    public void Show(LearningQuestionGate gate)
    {
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

        for (int i = 0; i < answerButtons.Length; i++)
        {
            bool hasAnswer = gate.answers != null && i < gate.answers.Length && !string.IsNullOrEmpty(gate.answers[i]);
            answerButtons[i].gameObject.SetActive(hasAnswer);
            answerButtons[i].interactable = hasAnswer;

            if (hasAnswer && i < answerLabels.Length)
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
        foreach (Button button in answerButtons)
        {
            button.interactable = interactable;
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
