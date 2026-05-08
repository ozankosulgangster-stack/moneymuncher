using UnityEngine;
using UnityEngine.Events;
using UnityEngine.SceneManagement;

public class MoneyMuncherGameManager : MonoBehaviour
{
    [Header("Round")]
    public int levelNumber = 1;
    public string levelName = "Treasure Island";
    public float roundDuration = 90f;
    public bool roundActive = true;

    [Header("Combo")]
    public float comboWindow = 2f;
    public int maxComboMultiplier = 10;

    [Header("Score")]
    public int grossScore;
    public int debt;
    public int comboMultiplier = 1;

    [Header("Events")]
    public UnityEvent onScoreChanged;
    public UnityEvent onRoundEnded;
    public UnityEvent onLevelCompleted;

    private float timeRemaining;
    private float comboTimer;
    private bool highScoreSaved;
    private bool levelCompleted;

    public float TimeRemaining => timeRemaining;
    public int NetWorth => grossScore - debt;
    public int BestNetWorth => PlayerPrefs.GetInt("MoneyMuncher.BestNetWorth", 0);
    public int SavedCoins => PlayerPrefs.GetInt("MoneyMuncher.SavedCoins", 0);
    public int SpeedGearLevel => PlayerPrefs.GetInt("MoneyMuncher.SpeedGearLevel", 0);
    public int MagnetGearLevel => PlayerPrefs.GetInt("MoneyMuncher.MagnetGearLevel", 0);
    public bool LevelCompleted => levelCompleted;
    public bool IsNextLevelUnlocked => PlayerPrefs.GetInt("MoneyMuncher.Level2Unlocked", 0) == 1;

    private void Start()
    {
        StartRound();
    }

    private void Update()
    {
        if (!roundActive)
        {
            return;
        }

        timeRemaining -= Time.deltaTime;
        comboTimer -= Time.deltaTime;

        if (comboTimer <= 0f)
        {
            comboMultiplier = 1;
        }

        if (timeRemaining <= 0f)
        {
            EndRound();
        }
    }

    public void StartRound()
    {
        grossScore = 0;
        debt = 0;
        comboMultiplier = 1;
        comboTimer = 0f;
        timeRemaining = roundDuration;
        roundActive = true;
        highScoreSaved = false;
        levelCompleted = false;
        onScoreChanged?.Invoke();
    }

    public void AddMoney(int value)
    {
        if (!roundActive)
        {
            return;
        }

        int earned = Mathf.Max(0, value) * comboMultiplier;
        grossScore += earned;
        comboMultiplier = Mathf.Min(comboMultiplier + 1, maxComboMultiplier);
        comboTimer = comboWindow;
        onScoreChanged?.Invoke();
    }

    public void AddDebt(int value)
    {
        if (!roundActive)
        {
            return;
        }

        debt += Mathf.Abs(value);
        comboMultiplier = 1;
        comboTimer = 0f;
        onScoreChanged?.Invoke();
    }

    public void ApplyTax(float percent)
    {
        if (!roundActive)
        {
            return;
        }

        int tax = Mathf.RoundToInt(grossScore * Mathf.Clamp01(percent));
        debt += tax;
        comboMultiplier = 1;
        comboTimer = 0f;
        onScoreChanged?.Invoke();
    }

    public void EndRound()
    {
        if (!roundActive)
        {
            return;
        }

        timeRemaining = 0f;
        roundActive = false;
        SaveBestScore();
        AddSavedCoins(Mathf.Max(0, NetWorth));
        onRoundEnded?.Invoke();
    }

    public void CompleteLevel()
    {
        if (!roundActive || levelCompleted)
        {
            return;
        }

        levelCompleted = true;
        roundActive = false;
        SaveBestScore();
        AddSavedCoins(Mathf.Max(0, NetWorth));

        if (levelNumber == 1)
        {
            PlayerPrefs.SetInt("MoneyMuncher.Level2Unlocked", 1);
            PlayerPrefs.Save();
        }

        onLevelCompleted?.Invoke();
        onRoundEnded?.Invoke();
    }

    public void RestartRound()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
    }

    public void LoadSceneByName(string sceneName)
    {
        SceneManager.LoadScene(sceneName);
    }

    public bool BuySpeedGear()
    {
        return BuyGear("MoneyMuncher.SpeedGearLevel", 150);
    }

    public bool BuyMagnetGear()
    {
        return BuyGear("MoneyMuncher.MagnetGearLevel", 150);
    }

    public void AddSavedCoins(int amount)
    {
        if (amount <= 0)
        {
            return;
        }

        PlayerPrefs.SetInt("MoneyMuncher.SavedCoins", SavedCoins + amount);
        PlayerPrefs.Save();
    }

    private bool BuyGear(string gearKey, int cost)
    {
        if (SavedCoins < cost)
        {
            return false;
        }

        PlayerPrefs.SetInt("MoneyMuncher.SavedCoins", SavedCoins - cost);
        PlayerPrefs.SetInt(gearKey, PlayerPrefs.GetInt(gearKey, 0) + 1);
        PlayerPrefs.Save();
        onScoreChanged?.Invoke();
        return true;
    }

    private void SaveBestScore()
    {
        if (highScoreSaved)
        {
            return;
        }

        highScoreSaved = true;

        if (NetWorth > BestNetWorth)
        {
            PlayerPrefs.SetInt("MoneyMuncher.BestNetWorth", NetWorth);
            PlayerPrefs.Save();
        }
    }
}
