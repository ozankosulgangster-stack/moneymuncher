# Money Muncher Unity Prototype

This folder contains the first build plan and Unity-ready scripts for Money Muncher, a fast arcade game about a cursed wallet eating valuable pickups while dodging ridiculous financial hazards.

## Files

- `Docs/MoneyMuncherDesign.md`: concept, core loop, online roadmap, and milestones.
- `Assets/Scripts/MoneyMuncherGameManager.cs`: round timer, score, debt, combo, and net worth.
- `Assets/Scripts/PlayerMuncherController.cs`: top-down player movement and munch behavior.
- `Assets/Scripts/MoneyPickup.cs`: good money, debt, tax, and power-up pickup behavior.
- `Assets/Scripts/PickupSpawner.cs`: weighted pickup spawning.
- `Assets/Scripts/TaxHazard.cs`: percentage-based tax hazard zone.
- `Assets/Scripts/MoneyMuncherHud.cs`: built-in Unity UI HUD binding.
- `Assets/Editor/MoneyMuncherPrototypeBuilder.cs`: one-click scene builder inside the Unity editor.

## Unity Setup

1. Open this folder in Unity Hub as a Unity project.
2. Let Unity generate the missing local `Library` files and compile scripts.
3. In the Unity top menu, click `Money Muncher > Build Campaign Levels` to create Level 1 and Level 2.
4. Open `Assets/Scenes/MoneyMuncherTreasureIsland.unity` for Level 1 or `Assets/Scenes/MoneyMuncherSoccerStadium.unity` for Level 2.
5. Press Play.

If your Unity version is different from `2022.3.50f1`, Unity may ask to upgrade or reserialize the project. That is okay for this prototype.

Controls:

- `WASD` or arrow keys to move.
- In the Treasure Island scene, press `1` through `6` to switch characters: wallet, chest, shark, dinosaur, penguin, or monster.
- Eat gold coins and green cash.
- On Treasure Island, grab emeralds and treasure chests for bigger scores.
- Avoid purple debt bombs, cursed idols, tax forms, and blue tax tide strips.
- At the end of Level 1, spend saved coins on Speed Shoes or Magnet Gear, then go to Level 2.
- In Level 2, push the soccer ball into either goal for a big bonus, collect trophies, and avoid red cards.
- Try to finish each round with the highest net worth.

## Prototype Goal

Get one 90-second arcade round playable:

- Move the wallet.
- Munch good pickups.
- Hit debt or tax hazards.
- Watch score, debt, combo, net worth, and timer update.
- End the round cleanly.

After that, the best next step is game feel: chomp animation, particles, pickup trails, sounds, and juicy score popups.

## Publishing Direction

The first public target is a Unity WebGL build on `moneymuncher.ca/kids`. Use `Money Muncher > Build Kids WebGL` to build into `Website/kids/play`, then upload the `Website/kids` folder contents to the site. See `Docs/MoneyMuncherKidsLaunch.md` for the launch checklist.
