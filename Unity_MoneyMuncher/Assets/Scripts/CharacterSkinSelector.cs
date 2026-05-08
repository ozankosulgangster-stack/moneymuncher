using UnityEngine;

public class CharacterSkinSelector : MonoBehaviour
{
    private static readonly KeyCode[] NumberKeys =
    {
        KeyCode.Alpha1,
        KeyCode.Alpha2,
        KeyCode.Alpha3,
        KeyCode.Alpha4,
        KeyCode.Alpha5,
        KeyCode.Alpha6,
        KeyCode.Alpha7,
        KeyCode.Alpha8,
        KeyCode.Alpha9
    };

    public GameObject[] skins;
    public WalletVisual[] skinVisuals;
    public PlayerMuncherController player;

    private int currentIndex;

    private void Awake()
    {
        if (player == null)
        {
            player = GetComponent<PlayerMuncherController>();
        }

        SelectSkin(0);
    }

    private void Update()
    {
        int keyCount = skins == null ? 0 : Mathf.Min(skins.Length, NumberKeys.Length);

        for (int i = 0; i < keyCount; i++)
        {
            if (Input.GetKeyDown(NumberKeys[i]))
            {
                SelectSkin(i);
            }
        }
    }

    public void SelectSkin(int index)
    {
        if (skins == null || skins.Length == 0)
        {
            return;
        }

        currentIndex = Mathf.Clamp(index, 0, skins.Length - 1);

        for (int i = 0; i < skins.Length; i++)
        {
            if (skins[i] != null)
            {
                skins[i].SetActive(i == currentIndex);
            }
        }

        if (player != null && skinVisuals != null && currentIndex < skinVisuals.Length)
        {
            player.walletVisual = skinVisuals[currentIndex];
        }
    }
}
