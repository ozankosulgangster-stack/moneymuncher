using UnityEngine;

[RequireComponent(typeof(Collider))]
public class LevelExit : MonoBehaviour
{
    public MoneyMuncherGameManager gameManager;

    private void Awake()
    {
        GetComponent<Collider>().isTrigger = true;

        Rigidbody body = GetComponent<Rigidbody>();
        if (body == null)
        {
            body = gameObject.AddComponent<Rigidbody>();
        }

        body.isKinematic = true;
        body.useGravity = false;

        if (gameManager == null)
        {
            gameManager = FindObjectOfType<MoneyMuncherGameManager>();
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        if (gameManager == null || other.GetComponent<PlayerMuncherController>() == null)
        {
            return;
        }

        gameManager.CompleteLevel();
    }
}
