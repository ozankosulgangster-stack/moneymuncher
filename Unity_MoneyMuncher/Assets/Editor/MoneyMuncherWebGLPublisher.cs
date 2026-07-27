using System.IO;
using System;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.Build.Reporting;
using UnityEngine;
using UnityEngine.SceneManagement;

public static class MoneyMuncherWebGLPublisher
{
    private static readonly string[] CampaignScenes =
    {
        "Assets/Scenes/MoneyMuncherLearningTrail.unity",
        "Assets/Scenes/MoneyMuncherTreasureIsland.unity",
        "Assets/Scenes/MoneyMuncherSoccerStadium.unity"
    };

    [MenuItem("Money Muncher/Build Kids WebGL")]
    public static void BuildKidsWebGL()
    {
        foreach (string scenePath in CampaignScenes)
        {
            if (!File.Exists(scenePath))
            {
                EditorUtility.DisplayDialog(
                    "Money Muncher WebGL",
                    "Campaign scenes are missing. Run Money Muncher > Build Campaign Levels first, then build WebGL.",
                    "OK");
                return;
            }
        }

        if (!ValidateCampaignScenes(out string validationIssue))
        {
            EditorUtility.DisplayDialog(
                "Money Muncher WebGL",
                $"WebGL build stopped because a campaign scene is incomplete:\n\n{validationIssue}\n\n" +
                "Run Money Muncher > Build Campaign Levels, then try again.",
                "OK");
            return;
        }

        string outputPath = GetKidsPlayFolder();
        Directory.CreateDirectory(outputPath);

        PlayerSettings.productName = "Money Muncher";
        PlayerSettings.companyName = "Money Muncher";
        EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.WebGL, BuildTarget.WebGL);

        BuildPlayerOptions options = new BuildPlayerOptions
        {
            scenes = CampaignScenes,
            locationPathName = outputPath,
            target = BuildTarget.WebGL,
            options = BuildOptions.None
        };

        BuildReport report = BuildPipeline.BuildPlayer(options);
        BuildSummary summary = report.summary;

        if (summary.result == BuildResult.Succeeded)
        {
            AddCacheBuster(outputPath);
            EditorUtility.DisplayDialog(
                "Money Muncher WebGL",
                $"WebGL build created for moneymuncher.ca/kids/play\n\n{outputPath}",
                "Ready");
        }
        else
        {
            EditorUtility.DisplayDialog(
                "Money Muncher WebGL",
                $"Build ended with status: {summary.result}. Check the Unity Console for details.",
                "OK");
        }
    }

    [MenuItem("Money Muncher/Open Kids Website Folder")]
    public static void OpenKidsWebsiteFolder()
    {
        EditorUtility.RevealInFinder(GetKidsFolder());
    }

    private static string GetKidsFolder()
    {
        string projectFolder = Path.GetFullPath(Path.Combine(Application.dataPath, ".."));
        string workspaceFolder = Path.GetFullPath(Path.Combine(projectFolder, ".."));
        return Path.Combine(workspaceFolder, "Website", "kids");
    }

    private static string GetKidsPlayFolder()
    {
        return Path.Combine(GetKidsFolder(), "play");
    }

    private static bool ValidateCampaignScenes(out string issue)
    {
        foreach (string scenePath in CampaignScenes)
        {
            Scene scene = SceneManager.GetSceneByPath(scenePath);
            bool closeWhenFinished = !scene.IsValid() || !scene.isLoaded;

            if (closeWhenFinished)
            {
                scene = EditorSceneManager.OpenScene(scenePath, OpenSceneMode.Additive);
            }

            try
            {
                int gameManagerCount = 0;
                int playerCount = 0;

                foreach (GameObject root in scene.GetRootGameObjects())
                {
                    gameManagerCount += root.GetComponentsInChildren<MoneyMuncherGameManager>(true).Length;
                    playerCount += root.GetComponentsInChildren<PlayerMuncherController>(true).Length;

                    foreach (LearningQuestionUI questionUI in root.GetComponentsInChildren<LearningQuestionUI>(true))
                    {
                        if (!questionUI.HasValidReferences(out string questionIssue))
                        {
                            issue = $"{scenePath}: {questionIssue}";
                            return false;
                        }
                    }
                }

                if (gameManagerCount != 1)
                {
                    issue = $"{scenePath}: expected one game manager, found {gameManagerCount}.";
                    return false;
                }

                if (playerCount == 0)
                {
                    issue = $"{scenePath}: player controller is missing.";
                    return false;
                }
            }
            finally
            {
                if (closeWhenFinished && scene.IsValid() && scene.isLoaded)
                {
                    EditorSceneManager.CloseScene(scene, true);
                }
            }
        }

        issue = "";
        return true;
    }

    private static void AddCacheBuster(string outputPath)
    {
        string indexPath = Path.Combine(outputPath, "index.html");
        if (!File.Exists(indexPath))
        {
            return;
        }

        string buildVersion = DateTime.UtcNow.ToString("yyyyMMddHHmmss");
        string html = File.ReadAllText(indexPath);
        string[] buildFiles =
        {
            "/play.loader.js",
            "/play.data.br",
            "/play.framework.js.br",
            "/play.wasm.br"
        };

        foreach (string buildFile in buildFiles)
        {
            html = html
                .Replace(buildFile + "\"", buildFile + $"?v={buildVersion}\"")
                .Replace(buildFile + "'", buildFile + $"?v={buildVersion}'");
        }

        File.WriteAllText(indexPath, html);
    }
}
