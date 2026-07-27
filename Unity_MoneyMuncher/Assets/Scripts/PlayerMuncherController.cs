using UnityEngine;

[RequireComponent(typeof(CharacterController))]
public class PlayerMuncherController : MonoBehaviour
{
    [Header("Movement")]
    public float moveSpeed = 8f;
    public float turnSpeed = 18f;

    [Header("Munching")]
    public float magnetRadius = 5f;
    public LayerMask pickupMask = ~0;

    [Header("Events")]
    public Animator animator;
    public ParticleSystem munchParticles;
    public WalletVisual walletVisual;

    private CharacterController controller;
    private MoneyMuncherGameManager gameManager;
    private float magnetTimer;

    private void Awake()
    {
        controller = GetComponent<CharacterController>();
        gameManager = FindObjectOfType<MoneyMuncherGameManager>();

        if (controller == null)
        {
            Debug.LogError("PlayerMuncherController requires a CharacterController.", this);
            enabled = false;
            return;
        }

        ApplyGearBonuses();
    }

    private void Update()
    {
        Move();
        UpdateMagnet();
    }

    public void Munch(MoneyPickup pickup)
    {
        if (pickup == null || gameManager == null)
        {
            return;
        }

        switch (pickup.kind)
        {
            case PickupKind.Good:
                gameManager.AddMoney(pickup.value);
                PlayMunchFeedback();
                break;
            case PickupKind.Debt:
                gameManager.AddDebt(pickup.value);
                break;
            case PickupKind.Tax:
                gameManager.ApplyTax(pickup.taxPercent);
                break;
            case PickupKind.PowerUp:
                ActivateMoneyMagnet(pickup.powerUpDuration);
                PlayMunchFeedback();
                break;
        }
    }

    private void Move()
    {
        float horizontal = Input.GetAxisRaw("Horizontal");
        float vertical = Input.GetAxisRaw("Vertical");
        Vector3 input = new Vector3(horizontal, 0f, vertical);
        Vector3 movement = Vector3.ClampMagnitude(input, 1f);

        controller.SimpleMove(movement * moveSpeed);

        if (movement.sqrMagnitude > 0.01f)
        {
            Quaternion targetRotation = Quaternion.LookRotation(movement);
            transform.rotation = Quaternion.Slerp(
                transform.rotation,
                targetRotation,
                turnSpeed * Time.deltaTime);
        }
    }

    private void ActivateMoneyMagnet(float duration)
    {
        magnetTimer = Mathf.Max(magnetTimer, duration);
    }

    private void UpdateMagnet()
    {
        if (magnetTimer <= 0f)
        {
            return;
        }

        magnetTimer -= Time.deltaTime;
        Collider[] pickups = Physics.OverlapSphere(transform.position, magnetRadius, pickupMask);

        foreach (Collider pickupCollider in pickups)
        {
            if (pickupCollider.TryGetComponent(out MoneyPickup pickup))
            {
                pickup.PullToward(transform);
            }
        }
    }

    private void PlayMunchFeedback()
    {
        if (animator != null)
        {
            animator.SetTrigger("Munch");
        }

        if (munchParticles != null)
        {
            munchParticles.Play();
        }

        if (walletVisual != null)
        {
            walletVisual.Chomp();
        }
    }

    private void ApplyGearBonuses()
    {
        int speedLevel = PlayerPrefs.GetInt("MoneyMuncher.SpeedGearLevel", 0);
        int magnetLevel = PlayerPrefs.GetInt("MoneyMuncher.MagnetGearLevel", 0);
        moveSpeed += speedLevel * 0.75f;
        magnetRadius += magnetLevel * 0.8f;
    }

    private void OnControllerColliderHit(ControllerColliderHit hit)
    {
        if (hit.rigidbody == null || hit.rigidbody.isKinematic)
        {
            return;
        }

        Vector3 pushDirection = new Vector3(hit.moveDirection.x, 0f, hit.moveDirection.z);
        hit.rigidbody.AddForce(pushDirection * 7f, ForceMode.Impulse);
    }
}
