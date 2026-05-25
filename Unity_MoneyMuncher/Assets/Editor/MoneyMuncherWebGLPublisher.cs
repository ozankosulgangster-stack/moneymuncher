using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

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
}
