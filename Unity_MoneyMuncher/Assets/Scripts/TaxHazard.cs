using UnityEngine;

[RequireComponent(typeof(Collider))]
public class TaxHazard : MonoBehaviour
{
    public float taxPercent = 0.05f;
    public float cooldown = 1.25f;

    private float nextHitTime;

    private void Reset()
    {
        Collider hazardCollider = GetComponent<Collider>();
        hazardCollider.isTrigger = true;
    }

    private void OnTriggerStay(Collider other)
    {
        if (Time.time < nextHitTime)
        {
            return;
        }

        if (!other.TryGetComponent(out PlayerMuncherController player))
        {
            return;
        }

        MoneyMuncherGameManager gameManager = FindObjectOfType<MoneyMuncherGameManager>();

        if (gameManager != null)
        {
            gameManager.ApplyTax(taxPercent);
            nextHitTime = Time.time + cooldown;
        }
    }
}
