using UnityEngine;
using UnityEngine.UI;

public class MoneyMuncherHud : MonoBehaviour
{
    public MoneyMuncherGameManager gameManager;

    [Header("UI")]
    public Text scoreLabel;
    public Text debtLabel;
    public Text netWorthLabel;
    public Text comboLabel;
    public Text timerLabel;
    public Text bestLabel;
    public Text resultsLabel;

    public GameObject resultsPanel;

    private void Awake()
    {
        if (gameManager == null)
        {
            gameManager = FindObjectOfType<MoneyMuncherGameManager>();
        }
    }

    private void OnEnable()
    {
        if (gameManager != null)
        {
            gameManager.onScoreChanged.AddListener(Refresh);
            gameManager.onRoundEnded.AddListener(Refresh);
        }
    }

    private void OnDisable()
    {
        if (gameManager != null)
        {
            gameManager.onScoreChanged.RemoveListener(Refresh);
            gameManager.onRoundEnded.RemoveListener(Refresh);
        }
    }

    private void Update()
    {
        Refresh();
    }

    private void Refresh()
    {
        if (gameManager == null)
        {
            return;
        }

        string score = $"Gross: ${gameManager.grossScore}";
        string debt = $"Debt: ${gameManager.debt}";
        string netWorth = $"Net: ${gameManager.NetWorth}";
        string combo = $"Combo x{gameManager.comboMultiplier}";
        string timer = $"Time: {Mathf.CeilToInt(gameManager.TimeRemaining)}";
        string best = $"Best: ${gameManager.BestNetWorth}";
        string results = $"Round Complete\nNet Worth: ${gameManager.NetWorth}\nBest: ${gameManager.BestNetWorth}";

        SetText(scoreLabel, score);
        SetText(debtLabel, debt);
        SetText(netWorthLabel, netWorth);
        SetText(comboLabel, combo);
        SetText(timerLabel, timer);
        SetText(bestLabel, best);
        SetText(resultsLabel, results);

        if (resultsPanel != null)
        {
            resultsPanel.SetActive(!gameManager.roundActive);
        }
    }

    private void SetText(Text uiText, string value)
    {
        if (uiText != null)
        {
            uiText.text = value;
        }
    }
}
