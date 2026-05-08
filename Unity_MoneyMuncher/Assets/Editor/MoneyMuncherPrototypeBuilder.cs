using System.IO;
using UnityEditor;
using UnityEditor.Events;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public static class MoneyMuncherPrototypeBuilder
{
    private const string ScenePath = "Assets/Scenes/MoneyMuncherPrototype.unity";
    private const string PrefabFolder = "Assets/GeneratedPrefabs";
    private const string MaterialFolder = "Assets/GeneratedMaterials";

    [MenuItem("Money Muncher/Build Prototype Scene")]
    public static void BuildPrototypeScene()
    {
        EnsureFolder("Assets", "Scenes");
        EnsureFolder("Assets", "GeneratedPrefabs");
        EnsureFolder("Assets", "GeneratedMaterials");

        Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        RenderSettings.ambientLight = new Color(0.65f, 0.72f, 0.86f);
        Camera.main?.gameObject.SetActive(false);

        Materials materials = CreateMaterials();
        CreateLighting();

        GameObject gameManagerObject = new GameObject("Game Manager");
        MoneyMuncherGameManager gameManager = gameManagerObject.AddComponent<MoneyMuncherGameManager>();
        gameManager.roundDuration = 90f;

        CreateArena(materials);
        GameObject player = CreatePlayer(materials);
        CreateCamera(player.transform);

        MoneyPickup coinPrefab = CreatePickupPrefab("Gold Coin", PickupKind.Good, 10, materials.coin, PrimitiveType.Sphere, 0.55f);
        MoneyPickup cashPrefab = CreatePickupPrefab("Cash Bundle", PickupKind.Good, 30, materials.cash, PrimitiveType.Cube, 0.7f);
        MoneyPickup debtPrefab = CreatePickupPrefab("Debt Bomb", PickupKind.Debt, 45, materials.debt, PrimitiveType.Sphere, 0.7f);
        MoneyPickup taxPrefab = CreatePickupPrefab("Tax Form", PickupKind.Tax, 0, materials.tax, PrimitiveType.Cube, 0.6f);
        taxPrefab.taxPercent = 0.08f;
        EditorUtility.SetDirty(taxPrefab);

        GameObject spawnerObject = new GameObject("Pickup Spawner");
        PickupSpawner spawner = spawnerObject.AddComponent<PickupSpawner>();
        spawner.arenaSize = new Vector2(18f, 12f);
        spawner.maxPickups = 45;
        spawner.spawnInterval = 0.25f;
        spawner.pickupParent = new GameObject("Spawned Pickups").transform;
        spawner.spawnTable = new[]
        {
            new PickupSpawner.SpawnEntry { prefab = coinPrefab, weight = 60 },
            new PickupSpawner.SpawnEntry { prefab = cashPrefab, weight = 24 },
            new PickupSpawner.SpawnEntry { prefab = debtPrefab, weight = 10 },
            new PickupSpawner.SpawnEntry { prefab = taxPrefab, weight = 6 },
        };

        CreateTaxHazards(materials);
        CreateHud(gameManager);

        EditorSceneManager.SaveScene(scene, ScenePath);
        AssetDatabase.SaveAssets();
        EditorUtility.DisplayDialog(
            "Money Muncher",
            "Prototype scene created at Assets/Scenes/MoneyMuncherPrototype.unity. Open it and press Play.",
            "Let's munch");
    }

    private static void EnsureFolder(string parent, string child)
    {
        string path = $"{parent}/{child}";

        if (!AssetDatabase.IsValidFolder(path))
        {
            AssetDatabase.CreateFolder(parent, child);
        }
    }

    private static Materials CreateMaterials()
    {
        return new Materials
        {
            floor = CreateMaterial("Floor", new Color(0.12f, 0.16f, 0.19f)),
            wall = CreateMaterial("Wall", new Color(0.04f, 0.05f, 0.06f)),
            wallet = CreateMaterial("Wallet", new Color(0.72f, 0.12f, 0.18f)),
            walletTrim = CreateMaterial("WalletTrim", new Color(1f, 0.77f, 0.18f)),
            coin = CreateMaterial("Coin", new Color(1f, 0.72f, 0.12f)),
            cash = CreateMaterial("Cash", new Color(0.15f, 0.75f, 0.38f)),
            debt = CreateMaterial("Debt", new Color(0.48f, 0.12f, 0.82f)),
            tax = CreateMaterial("Tax", new Color(0.18f, 0.68f, 1f)),
            hazard = CreateTransparentMaterial("TaxHazard", new Color(0.18f, 0.68f, 1f, 0.35f))
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
        GameObject lightObject = new GameObject("Key Light");
        Light light = lightObject.AddComponent<Light>();
        light.type = LightType.Directional;
        light.intensity = 1.1f;
        lightObject.transform.rotation = Quaternion.Euler(50f, -35f, 0f);
    }

    private static void CreateArena(Materials materials)
    {
        GameObject floor = GameObject.CreatePrimitive(PrimitiveType.Cube);
        floor.name = "Arena Floor";
        floor.transform.position = new Vector3(0f, -0.1f, 0f);
        floor.transform.localScale = new Vector3(22f, 0.2f, 16f);
        floor.GetComponent<Renderer>().sharedMaterial = materials.floor;

        CreateWall("North Wall", new Vector3(0f, 0.75f, 8f), new Vector3(22f, 1.5f, 0.5f), materials.wall);
        CreateWall("South Wall", new Vector3(0f, 0.75f, -8f), new Vector3(22f, 1.5f, 0.5f), materials.wall);
        CreateWall("East Wall", new Vector3(11f, 0.75f, 0f), new Vector3(0.5f, 1.5f, 16f), materials.wall);
        CreateWall("West Wall", new Vector3(-11f, 0.75f, 0f), new Vector3(0.5f, 1.5f, 16f), materials.wall);
    }

    private static void CreateWall(string name, Vector3 position, Vector3 scale, Material material)
    {
        GameObject wall = GameObject.CreatePrimitive(PrimitiveType.Cube);
        wall.name = name;
        wall.transform.position = position;
        wall.transform.localScale = scale;
        wall.GetComponent<Renderer>().sharedMaterial = material;
    }

    private static GameObject CreatePlayer(Materials materials)
    {
        GameObject player = new GameObject("Cursed Wallet Player");
        player.transform.position = new Vector3(0f, 0.55f, -4f);

        CharacterController controller = player.AddComponent<CharacterController>();
        controller.radius = 0.55f;
        controller.height = 1.2f;
        controller.center = new Vector3(0f, 0.5f, 0f);

        PlayerMuncherController muncher = player.AddComponent<PlayerMuncherController>();
        muncher.moveSpeed = 8.5f;
        muncher.magnetRadius = 5.5f;

        GameObject body = GameObject.CreatePrimitive(PrimitiveType.Cube);
        body.name = "Wallet Body";
        body.transform.SetParent(player.transform);
        body.transform.localPosition = new Vector3(0f, 0.4f, 0f);
        body.transform.localScale = new Vector3(1.4f, 0.55f, 1f);
        body.GetComponent<Renderer>().sharedMaterial = materials.wallet;
        Object.DestroyImmediate(body.GetComponent<Collider>());

        GameObject jaw = GameObject.CreatePrimitive(PrimitiveType.Cube);
        jaw.name = "Gold Zipper Jaw";
        jaw.transform.SetParent(player.transform);
        jaw.transform.localPosition = new Vector3(0f, 0.78f, 0.46f);
        jaw.transform.localScale = new Vector3(1.45f, 0.12f, 0.14f);
        jaw.GetComponent<Renderer>().sharedMaterial = materials.walletTrim;
        Object.DestroyImmediate(jaw.GetComponent<Collider>());

        WalletVisual walletVisual = player.AddComponent<WalletVisual>();
        walletVisual.jaw = jaw.transform;
        muncher.walletVisual = walletVisual;

        return player;
    }

    private static void CreateCamera(Transform target)
    {
        GameObject cameraObject = new GameObject("Main Camera");
        Camera camera = cameraObject.AddComponent<Camera>();
        cameraObject.tag = "MainCamera";
        camera.fieldOfView = 55f;
        camera.clearFlags = CameraClearFlags.Skybox;
        cameraObject.transform.position = new Vector3(0f, 15f, -12f);
        cameraObject.transform.LookAt(target.position);

        FollowCamera followCamera = cameraObject.AddComponent<FollowCamera>();
        followCamera.target = target;
    }

    private static MoneyPickup CreatePickupPrefab(string name, PickupKind kind, int value, Material material, PrimitiveType primitive, float scale)
    {
        string path = $"{PrefabFolder}/{name}.prefab";
        MoneyPickup existingPrefab = AssetDatabase.LoadAssetAtPath<MoneyPickup>(path);

        if (existingPrefab != null)
        {
            existingPrefab.kind = kind;
            existingPrefab.value = value;
            EditorUtility.SetDirty(existingPrefab);
            return existingPrefab;
        }

        GameObject pickupObject = GameObject.CreatePrimitive(primitive);
        pickupObject.name = name;
        pickupObject.transform.localScale = new Vector3(scale, scale, scale);
        pickupObject.GetComponent<Renderer>().sharedMaterial = material;

        Collider collider = pickupObject.GetComponent<Collider>();
        collider.isTrigger = true;

        MoneyPickup pickup = pickupObject.AddComponent<MoneyPickup>();
        pickup.kind = kind;
        pickup.value = value;

        GameObject prefab = PrefabUtility.SaveAsPrefabAsset(pickupObject, path);
        Object.DestroyImmediate(pickupObject);
        return prefab.GetComponent<MoneyPickup>();
    }

    private static void CreateTaxHazards(Materials materials)
    {
        CreateTaxHazard("Tax Laser A", new Vector3(-3f, 0.12f, 0f), new Vector3(0.35f, 0.25f, 10f), materials.hazard);
        CreateTaxHazard("Tax Laser B", new Vector3(4f, 0.12f, 1.5f), new Vector3(0.35f, 0.25f, 8f), materials.hazard);
    }

    private static void CreateTaxHazard(string name, Vector3 position, Vector3 scale, Material material)
    {
        GameObject hazard = GameObject.CreatePrimitive(PrimitiveType.Cube);
        hazard.name = name;
        hazard.transform.position = position;
        hazard.transform.localScale = scale;
        hazard.GetComponent<Renderer>().sharedMaterial = material;
        hazard.GetComponent<Collider>().isTrigger = true;
        hazard.AddComponent<TaxHazard>();
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
        hud.timerLabel = CreateHudText(canvasObject.transform, "Timer", "Time: 90", new Vector2(-18f, -18f), font, TextAnchor.UpperRight);
        hud.bestLabel = CreateHudText(canvasObject.transform, "Best", "Best: $0", new Vector2(-18f, -48f), font, TextAnchor.UpperRight);

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
        rect.sizeDelta = new Vector2(260f, 30f);
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

    private struct Materials
    {
        public Material floor;
        public Material wall;
        public Material wallet;
        public Material walletTrim;
        public Material coin;
        public Material cash;
        public Material debt;
        public Material tax;
        public Material hazard;
    }
}
