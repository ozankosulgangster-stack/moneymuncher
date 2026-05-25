using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneLoadButton : MonoBehaviour
{
    public string sceneName;

    public void LoadScene()
    {
        if (!string.IsNullOrEmpty(sceneName))
        {
            SceneManager.LoadScene(sceneName);
        }
    }
}
