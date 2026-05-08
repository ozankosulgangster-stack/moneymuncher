using UnityEngine;

[RequireComponent(typeof(Collider))]
public class SoccerGoal : MonoBehaviour
{
    public int goalValue = 250;
    public Transform ballResetPoint;

    private MoneyMuncherGameManager gameManager;

    private void Awake()
    {
        GetComponent<Collider>().isTrigger = true;
        gameManager = FindObjectOfType<MoneyMuncherGameManager>();
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.GetComponent<SoccerBall>() == null)
        {
            return;
        }

        if (gameManager != null)
        {
            gameManager.AddMoney(goalValue);
        }

        Rigidbody body = other.attachedRigidbody;
        if (body != null)
        {
            body.velocity = Vector3.zero;
            body.angularVelocity = Vector3.zero;
        }

        if (ballResetPoint != null)
        {
            other.transform.position = ballResetPoint.position;
        }
    }
}
