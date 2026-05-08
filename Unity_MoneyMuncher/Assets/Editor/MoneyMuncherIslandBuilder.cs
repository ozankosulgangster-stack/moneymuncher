using UnityEditor;
using UnityEditor.Events;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public static class MoneyMuncherIslandBuilder
{
    private const string ScenePath = "Assets/Scenes/MoneyMuncherTreasureIsland.unity";
    private const string PrefabFolder = "Assets/GeneratedPrefabs";
    private const string MaterialFolder = "Assets/GeneratedMaterials";

    [MenuItem("Money Muncher/Build Treasure Island Scene")]
    public static void BuildTreasureIslandScene()
    {
        EnsureFolder("Assets", "Scenes");
        EnsureFolder("Assets", "GeneratedPrefabs");
        EnsureFolder("Assets", "GeneratedMaterials");

        Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        RenderSettings.ambientLight = new Color(0.78f, 0.82f, 0.72f);

        IslandMaterials materials = CreateMaterials();
        CreateLighting();

        GameObject managerObject = new GameObject("Game Manager");
        MoneyMuncherGameManager gameManager = managerObject.AddComponent<MoneyMuncherGameManager>();
        gameManager.roundDuration = 120f;

        CreateIslandMap(materials);
        GameObject player = CreatePlayerWithSkins(materials);
        CreateCamera(player.transform);

        MoneyPickup coinPrefab = CreateSimplePickup("Island Gold Coin", PickupKind.Good, 15, materials.coin, PrimitiveType.Sphere, 0.55f);
        MoneyPickup gemPrefab = CreateSimplePickup("Emerald Gem", PickupKind.Good, 45, materials.gem, PrimitiveType.Capsule, 0.55f);
        MoneyPickup chestPrefab = CreateTreasureChestPickup(materials);
        MoneyPickup debtPrefab = CreateSimplePickup("Cursed Debt Idol", PickupKind.Debt, 60, materials.curse, PrimitiveType.Capsule, 0.75f);
        MoneyPickup taxPrefab = CreateSimplePickup("Island Tax Form", PickupKind.Tax, 0, materials.tax, PrimitiveType.Cube, 0.58f);
        taxPrefab.taxPercent = 0.08f;
        EditorUtility.SetDirty(taxPrefab);
        MoneyPickup magnetPrefab = CreateSimplePickup("Magnet Pearl", PickupKind.PowerUp, 0, materials.pearl, PrimitiveType.Sphere, 0.6f);
        magnetPrefab.powerUpDuration = 7f;
        EditorUtility.SetDirty(magnetPrefab);

        GameObject spawnerObject = new GameObject("Island Loot Spawner");
        PickupSpawner spawner = spawnerObject.AddComponent<PickupSpawner>();
        spawner.arenaSize = new Vector2(20f, 14f);
        spawner.maxPickups = 55;
        spawner.spawnInterval = 0.22f;
        spawner.pickupParent = new GameObject("Spawned Island Loot").transform;
        spawner.spawnTable = new[]
        {
            new PickupSpawner.SpawnEntry { prefab = coinPrefab, weight = 50 },
            new PickupSpawner.SpawnEntry { prefab = gemPrefab, weight = 22 },
            new PickupSpawner.SpawnEntry { prefab = chestPrefab, weight = 8 },
            new PickupSpawner.SpawnEntry { prefab = debtPrefab, weight = 13 },
            new PickupSpawner.SpawnEntry { prefab = taxPrefab, weight = 7 },
            new PickupSpawner.SpawnEntry { prefab = magnetPrefab, weight = 7 },
        };

        CreateIslandTaxLessonZones(materials);
        CreateHud(gameManager);

        EditorSceneManager.SaveScene(scene, ScenePath);
        AddSceneToBuildSettings(ScenePath);
        AssetDatabase.SaveAssets();
        EditorUtility.DisplayDialog(
            "Money Muncher",
            "Treasure Island scene created at Assets/Scenes/MoneyMuncherTreasureIsland.unity. Open it and press Play.",
            "Island time");
    }

    private static void EnsureFolder(string parent, string child)
    {
        string path = $"{parent}/{child}";

        if (!AssetDatabase.IsValidFolder(path))
        {
            AssetDatabase.CreateFolder(parent, child);
        }
    }

    private static IslandMaterials CreateMaterials()
    {
        return new IslandMaterials
        {
            sand = CreateMaterial("IslandSand", new Color(0.92f, 0.78f, 0.43f)),
            water = CreateTransparentMaterial("IslandWater", new Color(0.08f, 0.62f, 0.86f, 0.72f)),
            grass = CreateMaterial("IslandGrass", new Color(0.22f, 0.62f, 0.22f)),
            darkGrass = CreateMaterial("IslandDarkGrass", new Color(0.08f, 0.38f, 0.16f)),
            flower = CreateMaterial("IslandFlower", new Color(1f, 0.28f, 0.48f)),
            trunk = CreateMaterial("PalmTrunk", new Color(0.45f, 0.25f, 0.12f)),
            leaf = CreateMaterial("PalmLeaf", new Color(0.08f, 0.45f, 0.18f)),
            rock = CreateMaterial("IslandRock", new Color(0.36f, 0.36f, 0.34f)),
            coin = CreateMaterial("IslandGold", new Color(1f, 0.74f, 0.08f)),
            gem = CreateMaterial("EmeraldGem", new Color(0.02f, 0.95f, 0.5f)),
            chestWood = CreateMaterial("ChestWood", new Color(0.45f, 0.23f, 0.09f)),
            chestGold = CreateMaterial("ChestGold", new Color(1f, 0.76f, 0.13f)),
            curse = CreateMaterial("CursedPurple", new Color(0.48f, 0.1f, 0.74f)),
            tax = CreateMaterial("IslandTaxBlue", new Color(0.1f, 0.72f, 1f)),
            taxHazard = CreateTransparentMaterial("IslandTaxTide", new Color(0.1f, 0.72f, 1f, 0.35f)),
            pearl = CreateMaterial("MagnetPearl", new Color(0.95f, 0.98f, 1f)),
            wallet = CreateMaterial("IslandWalletRed", new Color(0.7f, 0.12f, 0.16f)),
            pirate = CreateMaterial("PirateChestPlayer", new Color(0.42f, 0.22f, 0.08f)),
            shark = CreateMaterial("SharkWalletBlue", new Color(0.18f, 0.45f, 0.72f)),
            dinosaur = CreateMaterial("DinosaurGreen", new Color(0.18f, 0.68f, 0.24f)),
            penguin = CreateMaterial("PenguinBlack", new Color(0.03f, 0.04f, 0.05f)),
            penguinBelly = CreateMaterial("PenguinBelly", new Color(0.92f, 0.95f, 0.9f)),
            beak = CreateMaterial("PenguinBeak", new Color(1f, 0.56f, 0.08f)),
            monster = CreateMaterial("MonsterPink", new Color(0.83f, 0.18f, 0.68f)),
            monsterHorn = CreateMaterial("MonsterHorn", new Color(0.9f, 0.95f, 1f)),
            trim = CreateMaterial("IslandGoldTrim", new Color(1f, 0.77f, 0.16f)),
            white = CreateMaterial("CharacterWhite", new Color(0.95f, 0.95f, 0.88f)),
            black = CreateMaterial("CharacterBlack", new Color(0.02f, 0.02f, 0.025f))
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
        GameObject sunObject = new GameObject("Island Sun");
        Light sun = sunObject.AddComponent<Light>();
        sun.type = LightType.Directional;
        sun.intensity = 1.25f;
        sunObject.transform.rotation = Quaternion.Euler(48f, -30f, 0f);
    }

    private static void CreateIslandMap(IslandMaterials materials)
    {
        CreateCube("Ocean", new Vector3(0f, -0.18f, 0f), new Vector3(32f, 0.16f, 24f), materials.water);
        CreateCube("Main Sand Island", new Vector3(0f, 0f, 0f), new Vector3(20f, 0.25f, 13f), materials.sand);
        CreateCube("West Beach Curve", new Vector3(-8.2f, 0.01f, 0.5f), new Vector3(5f, 0.22f, 8f), materials.sand);
        CreateCube("East Beach Curve", new Vector3(8.4f, 0.01f, -0.3f), new Vector3(5f, 0.22f, 8.4f), materials.sand);
        CreateCube("North Sand Bulge", new Vector3(0.8f, 0.01f, 5.6f), new Vector3(12f, 0.22f, 3.2f), materials.sand);
        CreateCube("South Sand Bulge", new Vector3(-0.6f, 0.01f, -5.6f), new Vector3(11f, 0.22f, 3.2f), materials.sand);

        CreateRaisedPatch("Grassy Center", new Vector3(0f, 0.18f, 0f), new Vector3(10.5f, 0.18f, 5.6f), materials.grass, materials.darkGrass);
        CreateRaisedPatch("Treasure Grove", new Vector3(-5.6f, 0.25f, 3.6f), new Vector3(4.2f, 0.24f, 2.8f), materials.grass, materials.darkGrass);
        CreateRaisedPatch("Gear Dock Hill", new Vector3(5.7f, 0.23f, -3.7f), new Vector3(4.8f, 0.22f, 2.8f), materials.grass, materials.darkGrass);

        CreateCube("North Driftwood Wall", new Vector3(0f, 0.55f, 7.4f), new Vector3(20f, 1.1f, 0.45f), materials.trunk);
        CreateCube("South Driftwood Wall", new Vector3(0f, 0.55f, -7.4f), new Vector3(20f, 1.1f, 0.45f), materials.trunk);
        CreateCube("East Driftwood Wall", new Vector3(10.8f, 0.55f, 0f), new Vector3(0.45f, 1.1f, 14f), materials.trunk);
        CreateCube("West Driftwood Wall", new Vector3(-10.8f, 0.55f, 0f), new Vector3(0.45f, 1.1f, 14f), materials.trunk);

        Vector3[] palmPositions =
        {
            new Vector3(-8f, 0.2f, 5f),
            new Vector3(7.5f, 0.2f, 4.5f),
            new Vector3(-7f, 0.2f, -5.2f),
            new Vector3(8.4f, 0.2f, -5.4f),
            new Vector3(-9.1f, 0.2f, 0.9f),
            new Vector3(9.2f, 0.2f, 1.2f),
            new Vector3(-4.8f, 0.34f, 4.6f),
            new Vector3(-6.4f, 0.34f, 2.9f),
            new Vector3(5.6f, 0.32f, -4.8f),
            new Vector3(7f, 0.32f, -3.1f),
            new Vector3(1.6f, 0.2f, 6.1f),
            new Vector3(-1.8f, 0.2f, -6.2f)
        };

        foreach (Vector3 palmPosition in palmPositions)
        {
            CreatePalmTree(palmPosition, materials);
        }

        CreateRockCluster(new Vector3(5.5f, 0.2f, -4.8f), materials);
        CreateRockCluster(new Vector3(-2f, 0.2f, 4.9f), materials);
        CreateRockCluster(new Vector3(8.5f, 0.2f, 5.7f), materials);
        CreateRockCluster(new Vector3(-8.7f, 0.2f, -3.9f), materials);

        CreateBushCluster(new Vector3(-4.2f, 0.4f, 2.2f), materials);
        CreateBushCluster(new Vector3(3.6f, 0.35f, 3.2f), materials);
        CreateBushCluster(new Vector3(6.2f, 0.35f, -1.9f), materials);
        CreateBushCluster(new Vector3(-6.5f, 0.35f, -1.5f), materials);

        CreateDecorativeChest(new Vector3(0f, 0.38f, 4.2f), materials);
        CreateDecorativeChest(new Vector3(-5.6f, 0.55f, 3.4f), materials);
        CreateTreasurePile(new Vector3(2.3f, 0.34f, 4.9f), materials);
        CreateTreasurePile(new Vector3(6.2f, 0.42f, -3.8f), materials);
        CreateDock(new Vector3(9.5f, 0.22f, -1.7f), materials);
        CreateSteppingStones(materials);
    }

    private static void CreateRaisedPatch(string name, Vector3 position, Vector3 scale, Material topMaterial, Material edgeMaterial)
    {
        GameObject edge = CreateCube($"{name} Raised Edge", position - new Vector3(0f, 0.08f, 0f), scale + new Vector3(0.45f, 0.08f, 0.45f), edgeMaterial);
        edge.GetComponent<Collider>().enabled = false;
        GameObject top = CreateCube(name, position, scale, topMaterial);
        top.GetComponent<Collider>().enabled = false;
    }

    private static void CreateIslandTaxLessonZones(IslandMaterials materials)
    {
        CreateTaxTide("Tax Tide Left", new Vector3(-4.8f, 0.14f, 0f), new Vector3(0.32f, 0.18f, 8.5f), materials.taxHazard);
        CreateTaxTide("Tax Tide Right", new Vector3(5.6f, 0.14f, -0.6f), new Vector3(0.32f, 0.18f, 7.2f), materials.taxHazard);
    }

    private static void CreateTaxTide(string name, Vector3 position, Vector3 scale, Material material)
    {
        GameObject tide = CreateCube(name, position, scale, material);
        tide.GetComponent<Collider>().isTrigger = true;
        TaxHazard hazard = tide.AddComponent<TaxHazard>();
        hazard.taxPercent = 0.04f;
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

    private static void CreatePalmTree(Vector3 position, IslandMaterials materials)
    {
        GameObject trunk = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        trunk.name = "Palm Trunk";
        trunk.transform.position = position + new Vector3(0f, 1.35f, 0f);
        trunk.transform.localScale = new Vector3(0.3f, 1.45f, 0.3f);
        trunk.transform.rotation = Quaternion.Euler(Random.Range(-4f, 4f), 0f, Random.Range(-7f, 7f));
        trunk.GetComponent<Renderer>().sharedMaterial = materials.trunk;
        Object.DestroyImmediate(trunk.GetComponent<Collider>());

        for (int i = 0; i < 6; i++)
        {
            GameObject leaf = GameObject.CreatePrimitive(PrimitiveType.Cube);
            leaf.name = "Palm Leaf";
            leaf.transform.position = position + new Vector3(0f, 2.95f, 0f);
            leaf.transform.rotation = Quaternion.Euler(0f, i * 60f, 18f + Random.Range(-5f, 5f));
            leaf.transform.localScale = new Vector3(0.5f, 0.12f, 2.35f);
            leaf.GetComponent<Renderer>().sharedMaterial = materials.leaf;
            Object.DestroyImmediate(leaf.GetComponent<Collider>());
        }
    }

    private static void CreateRockCluster(Vector3 position, IslandMaterials materials)
    {
        for (int i = 0; i < 3; i++)
        {
            GameObject rock = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            rock.name = "Smooth Island Rock";
            rock.transform.position = position + new Vector3(i * 0.55f, 0.25f, (i % 2) * 0.4f);
            rock.transform.localScale = new Vector3(0.8f, 0.45f, 0.65f);
            rock.GetComponent<Renderer>().sharedMaterial = materials.rock;
        }
    }

    private static void CreateDecorativeChest(Vector3 position, IslandMaterials materials)
    {
        GameObject chest = CreateCube("Decorative Treasure Chest", position, new Vector3(1.4f, 0.7f, 0.9f), materials.chestWood);
        Object.DestroyImmediate(chest.GetComponent<Collider>());
        GameObject band = CreateCube("Chest Gold Band", position + new Vector3(0f, 0.13f, 0f), new Vector3(1.5f, 0.12f, 0.96f), materials.chestGold);
        Object.DestroyImmediate(band.GetComponent<Collider>());
    }

    private static void CreateBushCluster(Vector3 position, IslandMaterials materials)
    {
        for (int i = 0; i < 5; i++)
        {
            GameObject bush = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            bush.name = "Island Bush";
            bush.transform.position = position + new Vector3((i - 2) * 0.32f, 0f, (i % 2) * 0.28f);
            bush.transform.localScale = new Vector3(0.58f, 0.42f, 0.58f);
            bush.GetComponent<Renderer>().sharedMaterial = i == 2 ? materials.flower : materials.darkGrass;
            Object.DestroyImmediate(bush.GetComponent<Collider>());
        }
    }

    private static void CreateTreasurePile(Vector3 position, IslandMaterials materials)
    {
        for (int i = 0; i < 7; i++)
        {
            GameObject coin = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            coin.name = "Decorative Coin Pile";
            coin.transform.position = position + new Vector3((i % 3) * 0.22f, i * 0.035f, (i / 3) * 0.2f);
            coin.transform.localScale = new Vector3(0.22f, 0.035f, 0.22f);
            coin.transform.rotation = Quaternion.Euler(90f, 0f, 0f);
            coin.GetComponent<Renderer>().sharedMaterial = materials.coin;
            Object.DestroyImmediate(coin.GetComponent<Collider>());
        }
    }

    private static void CreateDock(Vector3 position, IslandMaterials materials)
    {
        for (int i = 0; i < 5; i++)
        {
            GameObject plank = CreateCube("Gear Dock Plank", position + new Vector3(0f, 0f, i * 0.55f), new Vector3(2.1f, 0.14f, 0.42f), materials.trunk);
            Object.DestroyImmediate(plank.GetComponent<Collider>());
        }
    }

    private static void CreateSteppingStones(IslandMaterials materials)
    {
        Vector3[] stones =
        {
            new Vector3(-2.8f, 0.24f, -2.2f),
            new Vector3(-1.5f, 0.24f, -2.8f),
            new Vector3(-0.1f, 0.24f, -2.3f),
            new Vector3(1.2f, 0.24f, -2.8f),
            new Vector3(2.6f, 0.24f, -2.1f)
        };

        foreach (Vector3 stonePosition in stones)
        {
            GameObject stone = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            stone.name = "Stepping Stone";
            stone.transform.position = stonePosition;
            stone.transform.localScale = new Vector3(0.9f, 0.18f, 0.65f);
            stone.GetComponent<Renderer>().sharedMaterial = materials.rock;
            Object.DestroyImmediate(stone.GetComponent<Collider>());
        }
    }

    private static GameObject CreatePlayerWithSkins(IslandMaterials materials)
    {
        GameObject player = new GameObject("Muncher Player");
        player.transform.position = new Vector3(0f, 0.55f, -4.5f);

        CharacterController controller = player.AddComponent<CharacterController>();
        controller.radius = 0.55f;
        controller.height = 1.2f;
        controller.center = new Vector3(0f, 0.5f, 0f);

        PlayerMuncherController muncher = player.AddComponent<PlayerMuncherController>();
        muncher.moveSpeed = 8.5f;
        muncher.magnetRadius = 6f;

        GameObject wallet = CreateWalletSkin("Cursed Wallet Skin", player.transform, materials.wallet, materials.trim);
        GameObject chest = CreateWalletSkin("Pirate Chest Skin", player.transform, materials.pirate, materials.trim);
        GameObject shark = CreateSharkSkin(player.transform, materials);
        GameObject dinosaur = CreateDinosaurSkin(player.transform, materials);
        GameObject penguin = CreatePenguinSkin(player.transform, materials);
        GameObject monster = CreateMonsterSkin(player.transform, materials);

        CharacterSkinSelector selector = player.AddComponent<CharacterSkinSelector>();
        selector.player = muncher;
        selector.skins = new[] { wallet, chest, shark, dinosaur, penguin, monster };
        selector.skinVisuals = new[]
        {
            wallet.GetComponent<WalletVisual>(),
            chest.GetComponent<WalletVisual>(),
            shark.GetComponent<WalletVisual>(),
            dinosaur.GetComponent<WalletVisual>(),
            penguin.GetComponent<WalletVisual>(),
            monster.GetComponent<WalletVisual>()
        };
        selector.SelectSkin(0);

        return player;
    }

    private static GameObject CreateWalletSkin(string name, Transform parent, Material bodyMaterial, Material trimMaterial)
    {
        GameObject root = new GameObject(name);
        root.transform.SetParent(parent, false);

        GameObject body = GameObject.CreatePrimitive(PrimitiveType.Cube);
        body.name = "Body";
        body.transform.SetParent(root.transform, false);
        body.transform.localPosition = new Vector3(0f, 0.4f, 0f);
        body.transform.localScale = new Vector3(1.4f, 0.55f, 1f);
        body.GetComponent<Renderer>().sharedMaterial = bodyMaterial;
        Object.DestroyImmediate(body.GetComponent<Collider>());

        GameObject jaw = GameObject.CreatePrimitive(PrimitiveType.Cube);
        jaw.name = "Bite Jaw";
        jaw.transform.SetParent(root.transform, false);
        jaw.transform.localPosition = new Vector3(0f, 0.78f, 0.46f);
        jaw.transform.localScale = new Vector3(1.45f, 0.12f, 0.14f);
        jaw.GetComponent<Renderer>().sharedMaterial = trimMaterial;
        Object.DestroyImmediate(jaw.GetComponent<Collider>());

        WalletVisual visual = root.AddComponent<WalletVisual>();
        visual.jaw = jaw.transform;
        return root;
    }

    private static GameObject CreateSharkSkin(Transform parent, IslandMaterials materials)
    {
        GameObject root = CreateWalletSkin("Shark Wallet Skin", parent, materials.shark, materials.white);

        GameObject fin = GameObject.CreatePrimitive(PrimitiveType.Cube);
        fin.name = "Top Fin";
        fin.transform.SetParent(root.transform, false);
        fin.transform.localPosition = new Vector3(0f, 0.95f, -0.15f);
        fin.transform.localRotation = Quaternion.Euler(0f, 0f, 45f);
        fin.transform.localScale = new Vector3(0.28f, 0.55f, 0.12f);
        fin.GetComponent<Renderer>().sharedMaterial = materials.shark;
        Object.DestroyImmediate(fin.GetComponent<Collider>());

        GameObject eye = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        eye.name = "Shark Eye";
        eye.transform.SetParent(root.transform, false);
        eye.transform.localPosition = new Vector3(0.45f, 0.65f, 0.45f);
        eye.transform.localScale = new Vector3(0.14f, 0.14f, 0.14f);
        eye.GetComponent<Renderer>().sharedMaterial = materials.black;
        Object.DestroyImmediate(eye.GetComponent<Collider>());
        return root;
    }

    private static GameObject CreateDinosaurSkin(Transform parent, IslandMaterials materials)
    {
        GameObject root = new GameObject("Dinosaur Muncher Skin");
        root.transform.SetParent(parent, false);

        GameObject body = CreateSkinPart("Dino Body", root.transform, PrimitiveType.Capsule, new Vector3(0f, 0.48f, 0f), new Vector3(0.8f, 0.55f, 0.8f), materials.dinosaur);
        body.transform.localRotation = Quaternion.Euler(0f, 0f, 90f);
        CreateSkinPart("Dino Tail", root.transform, PrimitiveType.Cube, new Vector3(0f, 0.45f, -0.8f), new Vector3(0.38f, 0.24f, 0.9f), materials.dinosaur).transform.localRotation = Quaternion.Euler(25f, 0f, 0f);
        CreateSkinPart("Dino Head", root.transform, PrimitiveType.Cube, new Vector3(0f, 0.72f, 0.58f), new Vector3(0.95f, 0.5f, 0.65f), materials.dinosaur);

        GameObject jaw = CreateSkinPart("Dino Chomp Jaw", root.transform, PrimitiveType.Cube, new Vector3(0f, 0.47f, 0.86f), new Vector3(0.9f, 0.16f, 0.18f), materials.white);
        CreateSkinPart("Dino Eye Left", root.transform, PrimitiveType.Sphere, new Vector3(-0.28f, 0.9f, 0.88f), new Vector3(0.12f, 0.12f, 0.12f), materials.black);
        CreateSkinPart("Dino Eye Right", root.transform, PrimitiveType.Sphere, new Vector3(0.28f, 0.9f, 0.88f), new Vector3(0.12f, 0.12f, 0.12f), materials.black);

        for (int i = 0; i < 4; i++)
        {
            CreateSkinPart("Dino Back Spike", root.transform, PrimitiveType.Cube, new Vector3(0f, 1.0f, -0.45f + i * 0.28f), new Vector3(0.18f, 0.32f, 0.12f), materials.trim).transform.localRotation = Quaternion.Euler(0f, 0f, 45f);
        }

        WalletVisual visual = root.AddComponent<WalletVisual>();
        visual.jaw = jaw.transform;
        visual.openAngle = -28f;
        return root;
    }

    private static GameObject CreatePenguinSkin(Transform parent, IslandMaterials materials)
    {
        GameObject root = new GameObject("Penguin Muncher Skin");
        root.transform.SetParent(parent, false);

        CreateSkinPart("Penguin Body", root.transform, PrimitiveType.Capsule, new Vector3(0f, 0.55f, 0f), new Vector3(0.9f, 0.78f, 0.9f), materials.penguin);
        CreateSkinPart("Penguin Belly", root.transform, PrimitiveType.Sphere, new Vector3(0f, 0.48f, 0.38f), new Vector3(0.62f, 0.58f, 0.18f), materials.penguinBelly);
        CreateSkinPart("Penguin Eye Left", root.transform, PrimitiveType.Sphere, new Vector3(-0.22f, 1.06f, 0.48f), new Vector3(0.1f, 0.1f, 0.1f), materials.white);
        CreateSkinPart("Penguin Eye Right", root.transform, PrimitiveType.Sphere, new Vector3(0.22f, 1.06f, 0.48f), new Vector3(0.1f, 0.1f, 0.1f), materials.white);

        GameObject beak = CreateSkinPart("Penguin Beak Jaw", root.transform, PrimitiveType.Cube, new Vector3(0f, 0.88f, 0.68f), new Vector3(0.52f, 0.16f, 0.32f), materials.beak);
        CreateSkinPart("Penguin Left Flipper", root.transform, PrimitiveType.Cube, new Vector3(-0.62f, 0.45f, 0f), new Vector3(0.16f, 0.55f, 0.22f), materials.penguin).transform.localRotation = Quaternion.Euler(0f, 0f, -22f);
        CreateSkinPart("Penguin Right Flipper", root.transform, PrimitiveType.Cube, new Vector3(0.62f, 0.45f, 0f), new Vector3(0.16f, 0.55f, 0.22f), materials.penguin).transform.localRotation = Quaternion.Euler(0f, 0f, 22f);

        WalletVisual visual = root.AddComponent<WalletVisual>();
        visual.jaw = beak.transform;
        visual.openAngle = 24f;
        return root;
    }

    private static GameObject CreateMonsterSkin(Transform parent, IslandMaterials materials)
    {
        GameObject root = new GameObject("Monster Muncher Skin");
        root.transform.SetParent(parent, false);

        CreateSkinPart("Monster Body", root.transform, PrimitiveType.Sphere, new Vector3(0f, 0.55f, 0f), new Vector3(1.35f, 1f, 1.15f), materials.monster);
        CreateSkinPart("Monster Eye", root.transform, PrimitiveType.Sphere, new Vector3(0f, 0.9f, 0.58f), new Vector3(0.34f, 0.34f, 0.34f), materials.white);
        CreateSkinPart("Monster Pupil", root.transform, PrimitiveType.Sphere, new Vector3(0f, 0.9f, 0.78f), new Vector3(0.15f, 0.15f, 0.15f), materials.black);

        GameObject jaw = CreateSkinPart("Monster Mouth Jaw", root.transform, PrimitiveType.Cube, new Vector3(0f, 0.45f, 0.67f), new Vector3(0.9f, 0.18f, 0.18f), materials.black);
        CreateSkinPart("Monster Left Horn", root.transform, PrimitiveType.Cube, new Vector3(-0.38f, 1.22f, 0f), new Vector3(0.18f, 0.48f, 0.18f), materials.monsterHorn).transform.localRotation = Quaternion.Euler(0f, 0f, -25f);
        CreateSkinPart("Monster Right Horn", root.transform, PrimitiveType.Cube, new Vector3(0.38f, 1.22f, 0f), new Vector3(0.18f, 0.48f, 0.18f), materials.monsterHorn).transform.localRotation = Quaternion.Euler(0f, 0f, 25f);

        WalletVisual visual = root.AddComponent<WalletVisual>();
        visual.jaw = jaw.transform;
        visual.openAngle = -30f;
        return root;
    }

    private static GameObject CreateSkinPart(string name, Transform parent, PrimitiveType primitive, Vector3 localPosition, Vector3 localScale, Material material)
    {
        GameObject part = GameObject.CreatePrimitive(primitive);
        part.name = name;
        part.transform.SetParent(parent, false);
        part.transform.localPosition = localPosition;
        part.transform.localScale = localScale;
        part.GetComponent<Renderer>().sharedMaterial = material;
        Object.DestroyImmediate(part.GetComponent<Collider>());
        return part;
    }

    private static void CreateCamera(Transform target)
    {
        GameObject cameraObject = new GameObject("Main Camera");
        Camera camera = cameraObject.AddComponent<Camera>();
        cameraObject.tag = "MainCamera";
        camera.fieldOfView = 50f;
        cameraObject.transform.position = new Vector3(0f, 13f, -15f);
        cameraObject.transform.LookAt(target.position);

        FollowCamera followCamera = cameraObject.AddComponent<FollowCamera>();
        followCamera.target = target;
        followCamera.offset = new Vector3(0f, 13f, -15f);
        followCamera.followSpeed = 5.5f;
    }

    private static MoneyPickup CreateSimplePickup(string name, PickupKind kind, int value, Material material, PrimitiveType primitive, float scale)
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

    private static MoneyPickup CreateTreasureChestPickup(IslandMaterials materials)
    {
        string path = $"{PrefabFolder}/Treasure Chest Pickup.prefab";
        MoneyPickup existing = AssetDatabase.LoadAssetAtPath<MoneyPickup>(path);

        if (existing != null)
        {
            existing.kind = PickupKind.Good;
            existing.value = 150;
            EditorUtility.SetDirty(existing);
            return existing;
        }

        GameObject root = new GameObject("Treasure Chest Pickup");
        BoxCollider collider = root.AddComponent<BoxCollider>();
        collider.isTrigger = true;
        collider.size = new Vector3(1.35f, 0.9f, 0.95f);

        MoneyPickup pickup = root.AddComponent<MoneyPickup>();
        pickup.kind = PickupKind.Good;
        pickup.value = 150;
        root.AddComponent<PickupBobSpin>().spinSpeed = 35f;

        GameObject baseBox = GameObject.CreatePrimitive(PrimitiveType.Cube);
        baseBox.name = "Chest Base";
        baseBox.transform.SetParent(root.transform, false);
        baseBox.transform.localScale = new Vector3(1.3f, 0.55f, 0.9f);
        baseBox.GetComponent<Renderer>().sharedMaterial = materials.chestWood;
        Object.DestroyImmediate(baseBox.GetComponent<Collider>());

        GameObject lid = GameObject.CreatePrimitive(PrimitiveType.Cube);
        lid.name = "Gold Lid";
        lid.transform.SetParent(root.transform, false);
        lid.transform.localPosition = new Vector3(0f, 0.38f, 0f);
        lid.transform.localScale = new Vector3(1.38f, 0.18f, 0.96f);
        lid.GetComponent<Renderer>().sharedMaterial = materials.chestGold;
        Object.DestroyImmediate(lid.GetComponent<Collider>());

        GameObject prefab = PrefabUtility.SaveAsPrefabAsset(root, path);
        Object.DestroyImmediate(root);
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
        Text skinHelp = CreateHudText(canvasObject.transform, "Skin Help", "1 Wallet  2 Chest  3 Shark\n4 Dino  5 Penguin  6 Monster", new Vector2(-18f, -78f), font, TextAnchor.UpperRight);
        skinHelp.fontSize = 18;
        skinHelp.rectTransform.sizeDelta = new Vector2(560f, 52f);

        GameObject panel = new GameObject("Results Panel");
        panel.transform.SetParent(canvasObject.transform, false);
        Image image = panel.AddComponent<Image>();
        image.color = new Color(0.02f, 0.03f, 0.04f, 0.88f);
        RectTransform panelRect = panel.GetComponent<RectTransform>();
        panelRect.anchorMin = new Vector2(0.5f, 0.5f);
        panelRect.anchorMax = new Vector2(0.5f, 0.5f);
        panelRect.sizeDelta = new Vector2(520f, 360f);
        panelRect.anchoredPosition = Vector2.zero;

        hud.resultsPanel = panel;
        hud.resultsLabel = CreatePanelText(panel.transform, "Results Text", "Round Complete", new Vector2(0f, 116f), font, 28);

        Button restartButton = CreateRestartButton(panel.transform, font);
        UnityEventTools.AddPersistentListener(restartButton.onClick, gameManager.RestartRound);
        CreateGearShop(panel.transform, gameManager, font);
        panel.SetActive(false);
    }

    private static void CreateGearShop(Transform parent, MoneyMuncherGameManager gameManager, Font font)
    {
        GameObject shopObject = new GameObject("Gear Shop");
        shopObject.transform.SetParent(parent, false);
        GearShopUI shop = shopObject.AddComponent<GearShopUI>();
        shop.gameManager = gameManager;
        shop.nextLevelSceneName = "MoneyMuncherSoccerStadium";

        Text shopText = CreatePanelText(shopObject.transform, "Shop Text", "Gear Shop", new Vector2(0f, 18f), font, 18);
        shopText.rectTransform.sizeDelta = new Vector2(380f, 100f);
        shop.shopText = shopText;

        shop.speedButton = CreateShopButton(shopObject.transform, "Buy Speed", new Vector2(-120f, -72f), font);
        shop.magnetButton = CreateShopButton(shopObject.transform, "Buy Magnet", new Vector2(0f, -72f), font);
        shop.nextLevelButton = CreateShopButton(shopObject.transform, "Level 2", new Vector2(120f, -72f), font);

        UnityEventTools.AddPersistentListener(shop.speedButton.onClick, shop.BuySpeed);
        UnityEventTools.AddPersistentListener(shop.magnetButton.onClick, shop.BuyMagnet);
        UnityEventTools.AddPersistentListener(shop.nextLevelButton.onClick, shop.GoToNextLevel);
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
        rect.sizeDelta = new Vector2(360f, 30f);
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
        rect.anchoredPosition = new Vector2(0f, -136f);

        Text label = CreatePanelText(buttonObject.transform, "Label", "Restart", Vector2.zero, font, 22);
        label.color = Color.black;
        label.raycastTarget = false;
        return button;
    }

    private static Button CreateShopButton(Transform parent, string labelText, Vector2 position, Font font)
    {
        GameObject buttonObject = new GameObject(labelText);
        buttonObject.transform.SetParent(parent, false);
        Image image = buttonObject.AddComponent<Image>();
        image.color = new Color(0.2f, 0.74f, 0.42f);

        Button button = buttonObject.AddComponent<Button>();
        RectTransform rect = button.GetComponent<RectTransform>();
        rect.anchorMin = new Vector2(0.5f, 0.5f);
        rect.anchorMax = new Vector2(0.5f, 0.5f);
        rect.pivot = new Vector2(0.5f, 0.5f);
        rect.sizeDelta = new Vector2(105f, 34f);
        rect.anchoredPosition = position;

        Text label = CreatePanelText(buttonObject.transform, "Label", labelText, Vector2.zero, font, 15);
        label.color = Color.black;
        label.raycastTarget = false;
        label.rectTransform.sizeDelta = new Vector2(100f, 30f);
        return button;
    }

    private struct IslandMaterials
    {
        public Material sand;
        public Material water;
        public Material grass;
        public Material darkGrass;
        public Material flower;
        public Material trunk;
        public Material leaf;
        public Material rock;
        public Material coin;
        public Material gem;
        public Material chestWood;
        public Material chestGold;
        public Material curse;
        public Material tax;
        public Material taxHazard;
        public Material pearl;
        public Material wallet;
        public Material pirate;
        public Material shark;
        public Material dinosaur;
        public Material penguin;
        public Material penguinBelly;
        public Material beak;
        public Material monster;
        public Material monsterHorn;
        public Material trim;
        public Material white;
        public Material black;
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
}
