using UnityEngine;

public enum PickupKind
{
    Good,
    Debt,
    Tax,
    PowerUp
}

[RequireComponent(typeof(Collider))]
public class MoneyPickup : MonoBehaviour
{
    [Header("Pickup")]
    public PickupKind kind = PickupKind.Good;
    public int value = 10;
    public float taxPercent = 0.1f;
    public float magnetSpeed = 12f;
    public float collectDistance = 0.5f;

    [Header("Power-Up")]
    public float powerUpDuration = 6f;

    private Transform magnetTarget;
    public bool IsBeingPulled => magnetTarget != null;

    private void Reset()
    {
        Collider pickupCollider = GetComponent<Collider>();
        pickupCollider.isTrigger = true;
    }

    private void Update()
    {
        if (magnetTarget == null)
        {
            return;
        }

        transform.position = Vector3.MoveTowards(
            transform.position,
            magnetTarget.position,
            magnetSpeed * Time.deltaTime);

        if (Vector3.Distance(transform.position, magnetTarget.position) <= collectDistance)
        {
            Collect(magnetTarget.GetComponent<PlayerMuncherController>());
        }
    }

    public void PullToward(Transform target)
    {
        if (kind == PickupKind.Good || kind == PickupKind.PowerUp)
        {
            magnetTarget = target;
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        Collect(other.GetComponent<PlayerMuncherController>());
    }

    private void Collect(PlayerMuncherController player)
    {
        if (player == null)
        {
            return;
        }

        player.Munch(this);
        Destroy(gameObject);
    }
}
