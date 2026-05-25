using UnityEngine;

[RequireComponent(typeof(Collider))]
public class LearningQuestionGate : MonoBehaviour
{
    public string question;
    public string[] answers = new string[3];
    public int correctAnswerIndex;
    public string explanation;
    public int reward = 100;
    public int penalty = 25;
    public GameObject barrier;

    private MoneyMuncherGameManager gameManager;
    private bool answered;

    private void Awake()
    {
        GetComponent<Collider>().isTrigger = true;
        gameManager = FindObjectOfType<MoneyMuncherGameManager>();
    }

    private void OnTriggerEnter(Collider other)
    {
        if (answered || other.GetComponent<PlayerMuncherController>() == null)
        {
            return;
        }

        LearningQuestionUI ui = FindObjectOfType<LearningQuestionUI>();
        if (ui != null)
        {
            ui.Show(this);
        }
    }

    public void Answer(int answerIndex)
    {
        if (answered || gameManager == null)
        {
            return;
        }

        if (answerIndex == correctAnswerIndex)
        {
            answered = true;
            gameManager.AddMoney(reward);

            if (barrier != null)
            {
                barrier.SetActive(false);
            }
        }
        else
        {
            gameManager.AddDebt(penalty);
        }
    }

    public bool IsCorrect(int answerIndex)
    {
        return answerIndex == correctAnswerIndex;
    }
}
