using UnityEditor;

public static class MoneyMuncherCampaignBuilder
{
    [MenuItem("Money Muncher/Build Campaign Levels")]
    public static void BuildCampaignLevels()
    {
        MoneyMuncherIslandBuilder.BuildTreasureIslandScene();
        MoneyMuncherSoccerBuilder.BuildSoccerStadiumScene();
    }
}
