using UnityEngine;

public class PickupBobSpin : MonoBehaviour
{
    public float spinSpeed = 90f;
    public float bobHeight = 0.18f;
    public float bobSpeed = 3f;

    private Vector3 startPosition;
    private MoneyPickup pickup;

    private void Awake()
    {
        startPosition = transform.position;
        pickup = GetComponent<MoneyPickup>();
    }

    private void Update()
    {
        transform.Rotate(Vector3.up, spinSpeed * Time.deltaTime, Space.World);

        if (pickup != null && pickup.IsBeingPulled)
        {
            return;
        }

        float yOffset = Mathf.Sin(Time.time * bobSpeed) * bobHeight;
        transform.position = startPosition + new Vector3(0f, yOffset, 0f);
    }
}
