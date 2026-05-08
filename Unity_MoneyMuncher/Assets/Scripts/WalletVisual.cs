using System.Collections;
using UnityEngine;

public class WalletVisual : MonoBehaviour
{
    public Transform jaw;
    public float openAngle = 35f;
    public float chompDuration = 0.12f;

    private Coroutine chompRoutine;
    private Quaternion closedRotation;

    private void Awake()
    {
        if (jaw != null)
        {
            closedRotation = jaw.localRotation;
        }
    }

    public void Chomp()
    {
        if (jaw == null)
        {
            return;
        }

        if (chompRoutine != null)
        {
            StopCoroutine(chompRoutine);
        }

        chompRoutine = StartCoroutine(ChompRoutine());
    }

    private IEnumerator ChompRoutine()
    {
        Quaternion openRotation = closedRotation * Quaternion.Euler(openAngle, 0f, 0f);
        float halfDuration = chompDuration * 0.5f;

        for (float t = 0f; t < halfDuration; t += Time.deltaTime)
        {
            jaw.localRotation = Quaternion.Slerp(closedRotation, openRotation, t / halfDuration);
            yield return null;
        }

        for (float t = 0f; t < halfDuration; t += Time.deltaTime)
        {
            jaw.localRotation = Quaternion.Slerp(openRotation, closedRotation, t / halfDuration);
            yield return null;
        }

        jaw.localRotation = closedRotation;
    }
}
