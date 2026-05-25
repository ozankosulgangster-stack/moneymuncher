using UnityEditor;

public static class MoneyMuncherCampaignBuilder
{
    [MenuItem("Money Muncher/Build Campaign Levels")]
    public static void BuildCampaignLevels()
    {
        MoneyMuncherLearningTrailBuilder.BuildLearningTrailScene();
        MoneyMuncherIslandBuilder.BuildTreasureIslandScene();
        MoneyMuncherSoccerBuilder.BuildSoccerStadiumScene();
    }
}
