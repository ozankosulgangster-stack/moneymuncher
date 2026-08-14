using UnityEngine;

public class PickupSpawner : MonoBehaviour
{
    [System.Serializable]
    public struct SpawnEntry
    {
        public MoneyPickup prefab;
        public int weight;
    }

    public SpawnEntry[] spawnTable;
    public Vector2 arenaSize = new Vector2(18f, 12f);
    public int maxPickups = 40;
    public float spawnInterval = 0.35f;
    public Transform pickupParent;

    private float spawnTimer;

    private void Update()
    {
        spawnTimer -= Time.deltaTime;

        if (spawnTimer > 0f || CountPickups() >= maxPickups)
        {
            return;
        }

        spawnTimer = spawnInterval;
        SpawnPickup();
    }

    private void SpawnPickup()
    {
        MoneyPickup prefab = PickPrefab();

        if (prefab == null)
        {
            return;
        }

        Vector3 position = new Vector3(
            Random.Range(-arenaSize.x * 0.5f, arenaSize.x * 0.5f),
            0.5f,
            Random.Range(-arenaSize.y * 0.5f, arenaSize.y * 0.5f));

        Instantiate(prefab, position, Quaternion.identity, pickupParent);
    }

    private MoneyPickup PickPrefab()
    {
        if (spawnTable == null || spawnTable.Length == 0)
        {
            return null;
        }

        int totalWeight = 0;

        foreach (SpawnEntry entry in spawnTable)
        {
            totalWeight += Mathf.Max(0, entry.weight);
        }

        if (totalWeight <= 0)
        {
            return null;
        }

        int roll = Random.Range(0, totalWeight);

        foreach (SpawnEntry entry in spawnTable)
        {
            roll -= Mathf.Max(0, entry.weight);

            if (roll < 0)
            {
                return entry.prefab;
            }
        }

        return null;
    }

    private int CountPickups()
    {
        if (pickupParent == null)
        {
            return FindObjectsOfType<MoneyPickup>().Length;
        }

        return pickupParent.GetComponentsInChildren<MoneyPickup>().Length;
    }
}
