using UnityEditor;
using UnityEditor.Events;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public static class MoneyMuncherLearningTrailBuilder
{
    private const string ScenePath = "Assets/Scenes/MoneyMuncherLearningTrail.unity";
    private const string MaterialFolder = "Assets/GeneratedMaterials";

    [MenuItem("Money Muncher/Build Learning Trail Scene")]
    public static void BuildLearningTrailScene()
    {
        EnsureFolder("Assets", "Scenes");
        EnsureFolder("Assets", "GeneratedMaterials");

        Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        RenderSettings.ambientLight = new Color(0.78f, 0.84f, 0.9f);

        LearningMaterials materials = CreateMaterials();
        CreateLighting();

        GameObject managerObject = new GameObject("Game Manager");
        MoneyMuncherGameManager gameManager = managerObject.AddComponent<MoneyMuncherGameManager>();
        gameManager.levelNumber = 1;
        gameManager.levelName = "Money Learning Trail";
        gameManager.unlocksLevel2OnComplete = false;
        gameManager.roundDuration = 180f;

        CreateMap(materials);
        GameObject player = CreatePlayer(materials);
        CreateCamera(player.transform);
        CreateQuestionGates(materials);
        CreateFinishFlag(new Vector3(41f, 1.1f, 0f), materials, gameManager);
        CreateHud(gameManager);

        EditorSceneManager.SaveScene(scene, ScenePath);
        AddSceneToBuildSettings(ScenePath);
        AssetDatabase.SaveAssets();
        EditorUtility.DisplayDialog(
            "Money Muncher",
            "Learning Trail scene created at Assets/Scenes/MoneyMuncherLearningTrail.unity.",
            "Ready");
    }

    private static void EnsureFolder(string parent, string child)
    {
        string path = $"{parent}/{child}";

        if (!AssetDatabase.IsValidFolder(path))
        {
            AssetDatabase.CreateFolder(parent, child);
        }
    }

    private static LearningMaterials CreateMaterials()
    {
        return new LearningMaterials
        {
            sky = CreateMaterial("LearningSky", new Color(0.43f, 0.78f, 0.96f)),
            grass = CreateMaterial("LearningGrass", new Color(0.12f, 0.66f, 0.24f)),
            dirt = CreateMaterial("LearningDirt", new Color(0.5f, 0.28f, 0.12f)),
            coin = CreateMaterial("LearningCoin", new Color(1f, 0.78f, 0.08f)),
            question = CreateMaterial("QuestionBlockGold", new Color(1f, 0.58f, 0.06f)),
            barrier = CreateTransparentMaterial("QuestionGateBarrier", new Color(0.1f, 0.7f, 1f, 0.45f)),
            red = CreateMaterial("LearningRed", new Color(0.88f, 0.12f, 0.14f)),
            blue = CreateMaterial("LearningBlue", new Color(0.05f, 0.28f, 0.9f)),
            green = CreateMaterial("LearningGreen", new Color(0.08f, 0.55f, 0.22f)),
            black = CreateMaterial("LearningBlack", new Color(0.02f, 0.02f, 0.025f)),
            white = CreateMaterial("LearningWhite", Color.white)
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

    private static Material CreateTransparentMaterial(string name, Color color)
    {
        Material material = CreateMaterial(name, color);
        material.SetFloat("_Mode", 3f);
        material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
        material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
        material.SetInt("_ZWrite", 0);
        material.DisableKeyword("_ALPHATEST_ON");
        material.EnableKeyword("_ALPHABLEND_ON");
        material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
        material.renderQueue = 3000;
        return material;
    }

    private static void CreateLighting()
    {
        GameObject sunObject = new GameObject("Learning Trail Sun");
        Light sun = sunObject.AddComponent<Light>();
        sun.type = LightType.Directional;
        sun.intensity = 1.18f;
        sunObject.transform.rotation = Quaternion.Euler(48f, -35f, 0f);
    }

    private static void CreateMap(LearningMaterials materials)
    {
        CreateCube("Sky Backdrop", new Vector3(18f, 5f, 4.2f), new Vector3(55f, 11f, 0.35f), materials.sky);
        CreateCube("Learning Trail Ground", new Vector3(18f, -0.15f, 0f), new Vector3(52f, 0.3f, 4.2f), materials.grass);
        CreateCube("Learning Trail Dirt", new Vector3(18f, -0.65f, 0f), new Vector3(52f, 0.7f, 4.2f), materials.dirt);
        CreateCube("Back Lane Rail", new Vector3(18f, 0.7f, 2.2f), new Vector3(52f, 1.2f, 0.25f), materials.dirt);
        CreateCube("Front Lane Rail", new Vector3(18f, 0.7f, -2.2f), new Vector3(52f, 1.2f, 0.25f), materials.dirt);

        for (int i = 0; i < 8; i++)
        {
            CreateHill(new Vector3(-7f + i * 7.4f, 0.5f, 3.6f), materials);
        }

        for (int i = 0; i < 28; i++)
        {
            CreateCoin(new Vector3(-5f + i * 1.35f, 0.72f + Mathf.Sin(i * 0.7f) * 0.18f, i % 2 == 0 ? -0.65f : 0.65f), materials);
        }

        CreateQuestionBlock(new Vector3(7.2f, 1.25f, 0f), materials);
        CreateQuestionBlock(new Vector3(18.2f, 1.25f, 0f), materials);
        CreateQuestionBlock(new Vector3(29.2f, 1.25f, 0f), materials);
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

    private static void CreateHill(Vector3 position, LearningMaterials materials)
    {
        GameObject hill = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        hill.name = "Soft Background Hill";
        hill.transform.position = position;
        hill.transform.localScale = new Vector3(3.4f, 1.15f, 0.45f);
        hill.GetComponent<Renderer>().sharedMaterial = materials.green;
        Object.DestroyImmediate(hill.GetComponent<Collider>());
    }

    private static void CreateCoin(Vector3 position, LearningMaterials materials)
    {
        GameObject coin = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        coin.name = "Learning Coin";
        coin.transform.position = position;
        coin.transform.localScale = new Vector3(0.32f, 0.05f, 0.32f);
        coin.transform.rotation = Quaternion.Euler(90f, 0f, 0f);
        coin.GetComponent<Renderer>().sharedMaterial = materials.coin;
        coin.GetComponent<Collider>().isTrigger = true;

        MoneyPickup pickup = coin.AddComponent<MoneyPickup>();
        pickup.kind = PickupKind.Good;
        pickup.value = 10;
        coin.AddComponent<PickupBobSpin>().spinSpeed = 90f;
    }

    private static void CreateQuestionBlock(Vector3 position, LearningMaterials materials)
    {
        GameObject block = CreateCube("Question Block", position, new Vector3(0.9f, 0.9f, 0.9f), materials.question);
        Object.DestroyImmediate(block.GetComponent<Collider>());
    }

    private static GameObject CreatePlayer(LearningMaterials materials)
    {
        GameObject player = new GameObject("Learning Muncher Player");
        player.transform.position = new Vector3(-7.5f, 0.55f, 0f);

        CharacterController controller = player.AddComponent<CharacterController>();
        controller.radius = 0.5f;
        controller.height = 1.2f;
        controller.center = new Vector3(0f, 0.5f, 0f);

        PlayerMuncherController muncher = player.AddComponent<PlayerMuncherController>();
        muncher.moveSpeed = 7.4f;
        muncher.magnetRadius = 4.2f;

        GameObject body = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        body.name = "Learning Muncher Body";
        body.transform.SetParent(player.transform, false);
        body.transform.localPosition = new Vector3(0f, 0.55f, 0f);
        body.transform.localScale = new Vector3(1.15f, 0.85f, 1f);
        body.GetComponent<Renderer>().sharedMaterial = materials.red;
        Object.DestroyImmediate(body.GetComponent<Collider>());

        GameObject jaw = GameObject.CreatePrimitive(PrimitiveType.Cube);
        jaw.name = "Learning Muncher Jaw";
        jaw.transform.SetParent(player.transform, false);
        jaw.transform.localPosition = new Vector3(0f, 0.42f, 0.7f);
        jaw.transform.localScale = new Vector3(0.75f, 0.16f, 0.18f);
        jaw.GetComponent<Renderer>().sharedMaterial = materials.white;
        Object.DestroyImmediate(jaw.GetComponent<Collider>());

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
        camera.fieldOfView = 46f;
        cameraObject.transform.position = new Vector3(target.position.x + 3.5f, 7.5f, -10f);
        cameraObject.transform.LookAt(target.position + new Vector3(3f, 0f, 0f));

        FollowCamera followCamera = cameraObject.AddComponent<FollowCamera>();
        followCamera.target = target;
        followCamera.offset = new Vector3(3.5f, 7.5f, -10f);
        followCamera.followSpeed = 5.5f;
    }

    private static void CreateQuestionGates(LearningMaterials materials)
    {
        CreateGate(
            new Vector3(8f, 0.9f, 0f),
            "You found $10. What is the smartest first move?",
            new[] { "Save some of it", "Spend it all fast", "Hide it and forget it" },
            0,
            "Saving some money helps you prepare for bigger goals.",
            materials);

        CreateGate(
            new Vector3(19f, 0.9f, 0f),
            "What does investing mean?",
            new[] { "Buying random toys", "Putting money to work over time", "Losing money on purpose" },
            1,
            "Investing means using money to try to grow more money later.",
            materials);

        CreateGate(
            new Vector3(30f, 0.9f, 0f),
            "Why do we compare prices?",
            new[] { "To make slower choices", "To find better value", "To pay more taxes" },
            1,
            "Comparing prices helps you spend wisely and keep more coins.",
            materials);
    }

    private static void CreateGate(Vector3 position, string question, string[] answers, int correctIndex, string explanation, LearningMaterials materials)
    {
        GameObject barrier = CreateCube("Question Gate Barrier", position + new Vector3(0.65f, 0.25f, 0f), new Vector3(0.35f, 2.2f, 4.1f), materials.barrier);
        barrier.GetComponent<Collider>().isTrigger = false;

        GameObject trigger = CreateCube("Question Gate Trigger", position + new Vector3(-0.95f, 0f, 0f), new Vector3(1f, 1.6f, 3.8f), materials.question);
        trigger.GetComponent<Renderer>().enabled = false;
        trigger.GetComponent<Collider>().isTrigger = true;

        LearningQuestionGate gate = trigger.AddComponent<LearningQuestionGate>();
        gate.question = question;
        gate.answers = answers;
        gate.correctAnswerIndex = correctIndex;
        gate.explanation = explanation;
        gate.reward = 100;
        gate.penalty = 20;
        gate.barrier = barrier;
    }

    private static void CreateFinishFlag(Vector3 position, LearningMaterials materials, MoneyMuncherGameManager gameManager)
    {
        GameObject trigger = new GameObject("Learning Finish Flag Trigger");
        trigger.transform.position = position;
        BoxCollider collider = trigger.AddComponent<BoxCollider>();
        collider.size = new Vector3(1.4f, 2.4f, 3.6f);
        collider.isTrigger = true;

        LevelExit exit = trigger.AddComponent<LevelExit>();
        exit.gameManager = gameManager;

        CreateCube("Finish Flag Pole", position + new Vector3(0.35f, 0.8f, 0f), new Vector3(0.18f, 3.2f, 0.18f), materials.white);
        CreateCube("Finish Flag Banner", position + new Vector3(0.98f, 2f, 0f), new Vector3(1.2f, 0.65f, 0.18f), materials.blue);
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

        Font font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        hud.scoreLabel = CreateHudText(canvasObject.transform, "Score", "Gross: $0", new Vector2(18f, -18f), font, TextAnchor.UpperLeft);
        hud.debtLabel = CreateHudText(canvasObject.transform, "Debt", "Debt: $0", new Vector2(18f, -48f), font, TextAnchor.UpperLeft);
        hud.netWorthLabel = CreateHudText(canvasObject.transform, "Net Worth", "Net: $0", new Vector2(18f, -78f), font, TextAnchor.UpperLeft);
        hud.comboLabel = CreateHudText(canvasObject.transform, "Combo", "Combo x1", new Vector2(18f, -108f), font, TextAnchor.UpperLeft);
        hud.timerLabel = CreateHudText(canvasObject.transform, "Timer", "Time: 180", new Vector2(-18f, -18f), font, TextAnchor.UpperRight);
        hud.bestLabel = CreateHudText(canvasObject.transform, "Best", "Best: $0", new Vector2(-18f, -48f), font, TextAnchor.UpperRight);
        Text help = CreateHudText(canvasObject.transform, "Learning Help", "Run the trail, grab coins, answer gates", new Vector2(-18f, -78f), font, TextAnchor.UpperRight);
        help.fontSize = 18;
        help.rectTransform.sizeDelta = new Vector2(440f, 32f);

        CreateQuestionPanel(canvasObject.transform, font);
        CreateResultsPanel(canvasObject.transform, gameManager, hud, font);
    }

    private static void CreateQuestionPanel(Transform canvas, Font font)
    {
        GameObject panel = new GameObject("Question Panel");
        panel.transform.SetParent(canvas, false);
        Image image = panel.AddComponent<Image>();
        image.color = new Color(0.02f, 0.03f, 0.05f, 0.92f);
        RectTransform rect = panel.GetComponent<RectTransform>();
        rect.anchorMin = new Vector2(0.5f, 0.5f);
        rect.anchorMax = new Vector2(0.5f, 0.5f);
        rect.pivot = new Vector2(0.5f, 0.5f);
        rect.sizeDelta = new Vector2(640f, 330f);
        rect.anchoredPosition = Vector2.zero;

        LearningQuestionUI ui = canvas.gameObject.AddComponent<LearningQuestionUI>();
        ui.panel = panel;
        ui.questionLabel = CreatePanelText(panel.transform, "Question Text", "Question", new Vector2(0f, 102f), font, 24);
        ui.questionLabel.rectTransform.sizeDelta = new Vector2(570f, 86f);
        ui.feedbackLabel = CreatePanelText(panel.transform, "Feedback Text", "", new Vector2(0f, -108f), font, 18);
        ui.feedbackLabel.rectTransform.sizeDelta = new Vector2(560f, 56f);

        ui.answerButtons = new Button[3];
        ui.answerLabels = new Text[3];

        for (int i = 0; i < 3; i++)
        {
            Button button = CreateButton(panel.transform, $"Answer {i + 1}", new Vector2(0f, 42f - i * 54f), new Vector2(520f, 42f), font, 18);
            ui.answerButtons[i] = button;
            ui.answerLabels[i] = button.GetComponentInChildren<Text>();
        }
    }

    private static void CreateResultsPanel(Transform canvas, MoneyMuncherGameManager gameManager, MoneyMuncherHud hud, Font font)
    {
        GameObject panel = new GameObject("Results Panel");
        panel.transform.SetParent(canvas, false);
        Image image = panel.AddComponent<Image>();
        image.color = new Color(0.02f, 0.03f, 0.04f, 0.9f);
        RectTransform panelRect = panel.GetComponent<RectTransform>();
        panelRect.anchorMin = new Vector2(0.5f, 0.5f);
        panelRect.anchorMax = new Vector2(0.5f, 0.5f);
        panelRect.sizeDelta = new Vector2(520f, 300f);
        panelRect.anchoredPosition = Vector2.zero;

        hud.resultsPanel = panel;
        hud.resultsLabel = CreatePanelText(panel.transform, "Results Text", "Level Complete", new Vector2(0f, 70f), font, 26);

        Button restartButton = CreateButton(panel.transform, "Restart", new Vector2(-110f, -88f), new Vector2(180f, 44f), font, 21);
        UnityEventTools.AddPersistentListener(restartButton.onClick, gameManager.RestartRound);

        GameObject nextObject = CreateButton(panel.transform, "Treasure Island", new Vector2(110f, -88f), new Vector2(180f, 44f), font, 18).gameObject;
        SceneLoadButton loader = nextObject.AddComponent<SceneLoadButton>();
        loader.sceneName = "MoneyMuncherTreasureIsland";
        UnityEventTools.AddPersistentListener(nextObject.GetComponent<Button>().onClick, loader.LoadScene);
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
        rect.sizeDelta = new Vector2(430f, 30f);
        rect.anchoredPosition = position;
        return label;
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
        rect.sizeDelta = new Vector2(420f, 90f);
        rect.anchoredPosition = position;
        return label;
    }

    private static Button CreateButton(Transform parent, string labelText, Vector2 position, Vector2 size, Font font, int fontSize)
    {
        GameObject buttonObject = new GameObject(labelText);
        buttonObject.transform.SetParent(parent, false);
        Image image = buttonObject.AddComponent<Image>();
        image.color = new Color(1f, 0.72f, 0.12f);

        Button button = buttonObject.AddComponent<Button>();
        RectTransform rect = button.GetComponent<RectTransform>();
        rect.anchorMin = new Vector2(0.5f, 0.5f);
        rect.anchorMax = new Vector2(0.5f, 0.5f);
        rect.pivot = new Vector2(0.5f, 0.5f);
        rect.sizeDelta = size;
        rect.anchoredPosition = position;

        Text label = CreatePanelText(buttonObject.transform, "Label", labelText, Vector2.zero, font, fontSize);
        label.color = Color.black;
        label.raycastTarget = false;
        label.rectTransform.sizeDelta = size - new Vector2(10f, 6f);
        return button;
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

    private struct LearningMaterials
    {
        public Material sky;
        public Material grass;
        public Material dirt;
        public Material coin;
        public Material question;
        public Material barrier;
        public Material red;
        public Material blue;
        public Material green;
        public Material black;
        public Material white;
    }
}
