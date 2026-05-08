using UnityEngine;
using UnityEngine.UI;

public class GearShopUI : MonoBehaviour
{
    public MoneyMuncherGameManager gameManager;
    public Text shopText;
    public Button speedButton;
    public Button magnetButton;
    public Button nextLevelButton;
    public Text nextLevelButtonLabel;
    public string nextLevelSceneName = "MoneyMuncherSoccerStadium";

    private void Awake()
    {
        if (gameManager == null)
        {
            gameManager = FindObjectOfType<MoneyMuncherGameManager>();
        }
    }

    private void OnEnable()
    {
        Refresh();
    }

    public void BuySpeed()
    {
        if (gameManager != null)
        {
            gameManager.BuySpeedGear();
            Refresh();
        }
    }

    public void BuyMagnet()
    {
        if (gameManager != null)
        {
            gameManager.BuyMagnetGear();
            Refresh();
        }
    }

    public void GoToNextLevel()
    {
        if (gameManager != null && gameManager.IsNextLevelUnlocked)
        {
            gameManager.LoadSceneByName(nextLevelSceneName);
        }
    }

    public void Refresh()
    {
        if (gameManager == null || shopText == null)
        {
            return;
        }

        shopText.text =
            $"Gear Shop\nSaved Coins: ${gameManager.SavedCoins}\n" +
            $"Speed Shoes Lv {gameManager.SpeedGearLevel} - $150\n" +
            $"Magnet Gear Lv {gameManager.MagnetGearLevel} - $150";

        bool canBuy = gameManager.SavedCoins >= 150;

        if (speedButton != null)
        {
            speedButton.interactable = canBuy;
        }

        if (magnetButton != null)
        {
            magnetButton.interactable = canBuy;
        }

        if (nextLevelButton != null)
        {
            nextLevelButton.interactable = gameManager.IsNextLevelUnlocked;
        }

        if (nextLevelButtonLabel != null)
        {
            nextLevelButtonLabel.text = gameManager.IsNextLevelUnlocked ? "Play Level 2" : "Level 2 Locked";
        }
    }
}
