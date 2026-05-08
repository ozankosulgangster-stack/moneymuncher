using UnityEditor;
using UnityEditor.Events;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public static class MoneyMuncherSoccerBuilder
{
    private const string ScenePath = "Assets/Scenes/MoneyMuncherSoccerStadium.unity";
    private const string PrefabFolder = "Assets/GeneratedPrefabs";
    private const string MaterialFolder = "Assets/GeneratedMaterials";

    [MenuItem("Money Muncher/Build Soccer Stadium Scene")]
    public static void BuildSoccerStadiumScene()
    {
        EnsureFolder("Assets", "Scenes");
        EnsureFolder("Assets", "GeneratedPrefabs");
        EnsureFolder("Assets", "GeneratedMaterials");

        Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        RenderSettings.ambientLight = new Color(0.68f, 0.75f, 0.82f);

        StadiumMaterials materials = CreateMaterials();
        CreateLighting();

        GameObject managerObject = new GameObject("Game Manager");
        MoneyMuncherGameManager gameManager = managerObject.AddComponent<MoneyMuncherGameManager>();
        gameManager.roundDuration = 120f;

        CreateStadium(materials);
        GameObject player = CreatePlayer(materials);
        CreateCamera(player.transform);
        CreateSoccerBallAndGoals(materials);
        CreateSpawner(materials);
        CreateHud(gameManager);

        EditorSceneManager.SaveScene(scene, ScenePath);
        AddSceneToBuildSettings(ScenePath);
        AssetDatabase.SaveAssets();
        EditorUtility.DisplayDialog(
            "Money Muncher",
            "Soccer Stadium scene created at Assets/Scenes/MoneyMuncherSoccerStadium.unity. Open it and press Play.",
            "Kickoff");
    }

    private static void EnsureFolder(string parent, string child)
    {
        string path = $"{parent}/{child}";

        if (!AssetDatabase.IsValidFolder(path))
        {
            AssetDatabase.CreateFolder(parent, child);
        }
    }

    private static StadiumMaterials CreateMaterials()
    {
        return new StadiumMaterials
        {
            turf = CreateMaterial("SoccerTurf", new Color(0.06f, 0.42f, 0.14f)),
            line = CreateMaterial("SoccerLine", Color.white),
            stands = CreateMaterial("SoccerStands", new Color(0.16f, 0.19f, 0.23f)),
            redSeat = CreateMaterial("RedSeats", new Color(0.78f, 0.12f, 0.12f)),
            blueSeat = CreateMaterial("BlueSeats", new Color(0.08f, 0.22f, 0.8f)),
            gold = CreateMaterial("SoccerGold", new Color(1f, 0.72f, 0.08f)),
            white = CreateMaterial("SoccerWhite", Color.white),
            black = CreateMaterial("SoccerBlack", new Color(0.02f, 0.02f, 0.025f)),
            trophy = CreateMaterial("TrophyGold", new Color(1f, 0.78f, 0.12f)),
            card = CreateMaterial("PenaltyCard", new Color(1f, 0.1f, 0.05f)),
            player = CreateMaterial("SoccerMonsterGreen", new Color(0.12f, 0.72f, 0.35f)),
            trim = CreateMaterial("SoccerTrim", new Color(1f, 0.88f, 0.18f))
        };
    }

    private static Material CreateMaterial(string name, Color color)
    {
        string path = $"{MaterialFolder}/{name}.mat";
        Material material = AssetDatabase.LoadAssetAtPath<Material>(path);

        if (material == null)
        {
            material = new Material(Shader.Find("Standard"));
            AssetDatabase.CreateAsset(material, path);
        }

        material.color = color;
        return material;
    }

    private static void CreateLighting()
    {
        GameObject lightObject = new GameObject("Stadium Lights");
        Light light = lightObject.AddComponent<Light>();
        light.type = LightType.Directional;
        light.intensity = 1.2f;
        lightObject.transform.rotation = Quaternion.Euler(58f, -25f, 0f);
    }

    private static void CreateStadium(StadiumMaterials materials)
    {
        CreateCube("Field", new Vector3(0f, -0.1f, 0f), new Vector3(24f, 0.2f, 16f), materials.turf);
        CreateCube("Center Line", new Vector3(0f, 0.03f, 0f), new Vector3(0.16f, 0.05f, 15f), materials.line);
        CreateCube("Midfield Stripe", new Vector3(0f, 0.04f, 0f), new Vector3(5f, 0.04f, 0.12f), materials.line);
        CreateCube("North Stands", new Vector3(0f, 0.6f, 8.5f), new Vector3(25f, 1.2f, 1f), materials.stands);
        CreateCube("South Stands", new Vector3(0f, 0.6f, -8.5f), new Vector3(25f, 1.2f, 1f), materials.stands);
        CreateCube("West Stands", new Vector3(-12.5f, 0.6f, 0f), new Vector3(1f, 1.2f, 16f), materials.stands);
        CreateCube("East Stands", new Vector3(12.5f, 0.6f, 0f), new Vector3(1f, 1.2f, 16f), materials.stands);

        for (int i = 0; i < 8; i++)
        {
            Material seatMaterial = i % 2 == 0 ? materials.redSeat : materials.blueSeat;
            CreateCube("Fan Color Block", new Vector3(-8.5f + i * 2.4f, 1.35f, 8.35f), new Vector3(1.4f, 0.35f, 0.22f), seatMaterial);
            CreateCube("Fan Color Block", new Vector3(-8.5f + i * 2.4f, 1.35f, -8.35f), new Vector3(1.4f, 0.35f, 0.22f), seatMaterial);
        }
    }

    private static GameObject CreateCube(string name, Vector3 position, Vector3 scale, Material material)
    {
        GameObject obj = GameObject.CreatePrimitive(PrimitiveType.Cube);
        obj.name = name;
        obj.transform.position = position;
        obj.transform.localScale = scale;
        obj.GetComponent<Renderer>().sharedMaterial = material;
        return obj;
    }

    private static GameObject CreatePlayer(StadiumMaterials materials)
    {
        GameObject player = new GameObject("Soccer Muncher Player");
        player.transform.position = new Vector3(0f, 0.55f, -4.5f);

        CharacterController controller = player.AddComponent<CharacterController>();
        controller.radius = 0.55f;
        controller.height = 1.2f;
        controller.center = new Vector3(0f, 0.5f, 0f);

        PlayerMuncherController muncher = player.AddComponent<PlayerMuncherController>();
        muncher.moveSpeed = 8.8f;
        muncher.magnetRadius = 5.5f;

        GameObject body = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        body.name = "Soccer Monster Body";
        body.transform.SetParent(player.transform, false);
        body.transform.localPosition = new Vector3(0f, 0.55f, 0f);
        body.transform.localScale = new Vector3(1.25f, 0.95f, 1.1f);
        body.GetComponent<Renderer>().sharedMaterial = materials.player;
        Object.DestroyImmediate(body.GetComponent<Collider>());

        GameObject jaw = GameObject.CreatePrimitive(PrimitiveType.Cube);
        jaw.name = "Soccer Chomp Jaw";
        jaw.transform.SetParent(player.transform, false);
        jaw.transform.localPosition = new Vector3(0f, 0.45f, 0.72f);
        jaw.transform.localScale = new Vector3(0.9f, 0.18f, 0.18f);
        jaw.GetComponent<Renderer>().sharedMaterial = materials.black;
        Object.DestroyImmediate(jaw.GetComponent<Collider>());

        GameObject scarf = GameObject.CreatePrimitive(PrimitiveType.Cube);
        scarf.name = "Team Scarf";
        scarf.transform.SetParent(player.transform, false);
        scarf.transform.localPosition = new Vector3(0f, 0.82f, 0.05f);
        scarf.transform.localScale = new Vector3(1.15f, 0.12f, 0.2f);
        scarf.GetComponent<Renderer>().sharedMaterial = materials.trim;
        Object.DestroyImmediate(scarf.GetComponent<Collider>());

        WalletVisual visual = player.AddComponent<WalletVisual>();
        visual.jaw = jaw.transform;
        muncher.walletVisual = visual;
        return player;
    }

    private static void CreateCamera(Transform target)
    {
        GameObject cameraObject = new GameObject("Main Camera");
        Camera camera = cameraObject.AddComponent<Camera>();
        cameraObject.tag = "MainCamera";
        camera.fieldOfView = 55f;
        cameraObject.transform.position = new Vector3(0f, 15f, -12f);
        cameraObject.transform.LookAt(target.position);

        FollowCamera followCamera = cameraObject.AddComponent<FollowCamera>();
        followCamera.target = target;
    }

    private static void CreateSoccerBallAndGoals(StadiumMaterials materials)
    {
        GameObject resetPoint = new GameObject("Ball Reset Point");
        resetPoint.transform.position = new Vector3(0f, 0.55f, 0f);

        GameObject ball = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        ball.name = "Soccer Ball";
        ball.transform.position = resetPoint.transform.position;
        ball.transform.localScale = new Vector3(0.65f, 0.65f, 0.65f);
        ball.GetComponent<Renderer>().sharedMaterial = materials.white;
        ball.AddComponent<SoccerBall>();
        Rigidbody ballBody = ball.AddComponent<Rigidbody>();
        ballBody.drag = 0.45f;
        ballBody.angularDrag = 0.65f;

        CreateGoal("Left Goal", new Vector3(-11.2f, 0.65f, 0f), new Vector3(0.4f, 1.2f, 4f), resetPoint.transform, materials);
        CreateGoal("Right Goal", new Vector3(11.2f, 0.65f, 0f), new Vector3(0.4f, 1.2f, 4f), resetPoint.transform, materials);
    }

    private static void CreateGoal(string name, Vector3 position, Vector3 scale, Transform resetPoint, StadiumMaterials materials)
    {
        GameObject goal = CreateCube(name, position, scale, materials.line);
        goal.GetComponent<Collider>().isTrigger = true;
        SoccerGoal soccerGoal = goal.AddComponent<SoccerGoal>();
        soccerGoal.ballResetPoint = resetPoint;
        soccerGoal.goalValue = 250;
    }

    private static void CreateSpawner(StadiumMaterials materials)
    {
        MoneyPickup coinPrefab = CreatePickup("Stadium Coin", PickupKind.Good, 20, materials.gold, PrimitiveType.Sphere, 0.5f);
        MoneyPickup trophyPrefab = CreatePickup("Mini Trophy", PickupKind.Good, 80, materials.trophy, PrimitiveType.Capsule, 0.65f);
        MoneyPickup cardPrefab = CreatePickup("Red Card Debt", PickupKind.Debt, 75, materials.card, PrimitiveType.Cube, 0.65f);
        MoneyPickup whistlePrefab = CreatePickup("Referee Whistle Magnet", PickupKind.PowerUp, 0, materials.white, PrimitiveType.Capsule, 0.5f);
        whistlePrefab.powerUpDuration = 6f;
        EditorUtility.SetDirty(whistlePrefab);

        GameObject spawnerObject = new GameObject("Stadium Pickup Spawner");
        PickupSpawner spawner = spawnerObject.AddComponent<PickupSpawner>();
        spawner.arenaSize = new Vector2(20f, 12f);
        spawner.maxPickups = 45;
        spawner.spawnInterval = 0.26f;
        spawner.pickupParent = new GameObject("Spawned Stadium Pickups").transform;
        spawner.spawnTable = new[]
        {
            new PickupSpawner.SpawnEntry { prefab = coinPrefab, weight = 55 },
            new PickupSpawner.SpawnEntry { prefab = trophyPrefab, weight = 18 },
            new PickupSpawner.SpawnEntry { prefab = cardPrefab, weight = 18 },
            new PickupSpawner.SpawnEntry { prefab = whistlePrefab, weight = 9 },
        };
    }

    private static MoneyPickup CreatePickup(string name, PickupKind kind, int value, Material material, PrimitiveType primitive, float scale)
    {
        string path = $"{PrefabFolder}/{name}.prefab";
        MoneyPickup existing = AssetDatabase.LoadAssetAtPath<MoneyPickup>(path);

        if (existing != null)
        {
            existing.kind = kind;
            existing.value = value;
            EditorUtility.SetDirty(existing);
            return existing;
        }

        GameObject obj = GameObject.CreatePrimitive(primitive);
        obj.name = name;
        obj.transform.localScale = new Vector3(scale, scale, scale);
        obj.GetComponent<Renderer>().sharedMaterial = material;
        obj.GetComponent<Collider>().isTrigger = true;

        MoneyPickup pickup = obj.AddComponent<MoneyPickup>();
        pickup.kind = kind;
        pickup.value = value;
        obj.AddComponent<PickupBobSpin>();

        GameObject prefab = PrefabUtility.SaveAsPrefabAsset(obj, path);
        Object.DestroyImmediate(obj);
        return prefab.GetComponent<MoneyPickup>();
    }

    private static void CreateHud(MoneyMuncherGameManager gameManager)
    {
        GameObject canvasObject = new GameObject("HUD Canvas");
        Canvas canvas = canvasObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvasObject.AddComponent<CanvasScaler>().uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        canvasObject.AddComponent<GraphicRaycaster>();

        GameObject eventSystemObject = new GameObject("EventSystem");
        eventSystemObject.AddComponent<EventSystem>();
        eventSystemObject.AddComponent<StandaloneInputModule>();

        MoneyMuncherHud hud = canvasObject.AddComponent<MoneyMuncherHud>();
        hud.gameManager = gameManager;

        Font font = Resources.GetBuiltinResource<Font>("Arial.ttf");
        hud.scoreLabel = CreateHudText(canvasObject.transform, "Score", "Gross: $0", new Vector2(18f, -18f), font, TextAnchor.UpperLeft);
        hud.debtLabel = CreateHudText(canvasObject.transform, "Debt", "Debt: $0", new Vector2(18f, -48f), font, TextAnchor.UpperLeft);
        hud.netWorthLabel = CreateHudText(canvasObject.transform, "Net Worth", "Net: $0", new Vector2(18f, -78f), font, TextAnchor.UpperLeft);
        hud.comboLabel = CreateHudText(canvasObject.transform, "Combo", "Combo x1", new Vector2(18f, -108f), font, TextAnchor.UpperLeft);
        hud.timerLabel = CreateHudText(canvasObject.transform, "Timer", "Time: 120", new Vector2(-18f, -18f), font, TextAnchor.UpperRight);
        hud.bestLabel = CreateHudText(canvasObject.transform, "Best", "Best: $0", new Vector2(-18f, -48f), font, TextAnchor.UpperRight);
        Text help = CreateHudText(canvasObject.transform, "Soccer Help", "Kick ball into goals: +$250\nCollect trophies, avoid red cards", new Vector2(-18f, -78f), font, TextAnchor.UpperRight);
        help.fontSize = 18;
        help.rectTransform.sizeDelta = new Vector2(440f, 52f);

        GameObject panel = new GameObject("Results Panel");
        panel.transform.SetParent(canvasObject.transform, false);
        Image image = panel.AddComponent<Image>();
        image.color = new Color(0.02f, 0.03f, 0.04f, 0.88f);
        RectTransform panelRect = panel.GetComponent<RectTransform>();
        panelRect.anchorMin = new Vector2(0.5f, 0.5f);
        panelRect.anchorMax = new Vector2(0.5f, 0.5f);
        panelRect.sizeDelta = new Vector2(420f, 260f);
        panelRect.anchoredPosition = Vector2.zero;

        hud.resultsPanel = panel;
        hud.resultsLabel = CreatePanelText(panel.transform, "Results Text", "Round Complete", new Vector2(0f, 44f), font, 28);

        Button restartButton = CreateRestartButton(panel.transform, font);
        UnityEventTools.AddPersistentListener(restartButton.onClick, gameManager.RestartRound);
        panel.SetActive(false);
    }

    private static Text CreateHudText(Transform parent, string name, string text, Vector2 position, Font font, TextAnchor alignment)
    {
        GameObject textObject = new GameObject(name);
        textObject.transform.SetParent(parent, false);
        Text label = textObject.AddComponent<Text>();
        label.text = text;
        label.font = font;
        label.fontSize = 22;
        label.color = Color.white;
        label.alignment = alignment;

        RectTransform rect = label.GetComponent<RectTransform>();
        rect.anchorMin = alignment == TextAnchor.UpperRight ? new Vector2(1f, 1f) : new Vector2(0f, 1f);
        rect.anchorMax = rect.anchorMin;
        rect.pivot = alignment == TextAnchor.UpperRight ? new Vector2(1f, 1f) : new Vector2(0f, 1f);
        rect.sizeDelta = new Vector2(320f, 30f);
        rect.anchoredPosition = position;
        return label;
    }

    private static void AddSceneToBuildSettings(string scenePath)
    {
        EditorBuildSettingsScene[] scenes = EditorBuildSettings.scenes;

        foreach (EditorBuildSettingsScene scene in scenes)
        {
            if (scene.path == scenePath)
            {
                return;
            }
        }

        EditorBuildSettingsScene[] updatedScenes = new EditorBuildSettingsScene[scenes.Length + 1];
        scenes.CopyTo(updatedScenes, 0);
        updatedScenes[updatedScenes.Length - 1] = new EditorBuildSettingsScene(scenePath, true);
        EditorBuildSettings.scenes = updatedScenes;
    }

    private static Text CreatePanelText(Transform parent, string name, string text, Vector2 position, Font font, int fontSize)
    {
        GameObject textObject = new GameObject(name);
        textObject.transform.SetParent(parent, false);
        Text label = textObject.AddComponent<Text>();
        label.text = text;
        label.font = font;
        label.fontSize = fontSize;
        label.color = Color.white;
        label.alignment = TextAnchor.MiddleCenter;

        RectTransform rect = label.GetComponent<RectTransform>();
        rect.anchorMin = new Vector2(0.5f, 0.5f);
        rect.anchorMax = new Vector2(0.5f, 0.5f);
        rect.pivot = new Vector2(0.5f, 0.5f);
        rect.sizeDelta = new Vector2(360f, 120f);
        rect.anchoredPosition = position;
        return label;
    }

    private static Button CreateRestartButton(Transform parent, Font font)
    {
        GameObject buttonObject = new GameObject("Restart Button");
        buttonObject.transform.SetParent(parent, false);
        Image image = buttonObject.AddComponent<Image>();
        image.color = new Color(1f, 0.72f, 0.12f);

        Button button = buttonObject.AddComponent<Button>();
        RectTransform rect = button.GetComponent<RectTransform>();
        rect.anchorMin = new Vector2(0.5f, 0.5f);
        rect.anchorMax = new Vector2(0.5f, 0.5f);
        rect.pivot = new Vector2(0.5f, 0.5f);
        rect.sizeDelta = new Vector2(180f, 46f);
        rect.anchoredPosition = new Vector2(0f, -82f);

        Text label = CreatePanelText(buttonObject.transform, "Label", "Restart", Vector2.zero, font, 22);
        label.color = Color.black;
        label.raycastTarget = false;
        return button;
    }

    private struct StadiumMaterials
    {
        public Material turf;
        public Material line;
        public Material stands;
        public Material redSeat;
        public Material blueSeat;
        public Material gold;
        public Material white;
        public Material black;
        public Material trophy;
        public Material card;
        public Material player;
        public Material trim;
    }
}
