# Money Muncher

Money Muncher is a Unity WebGL kids game about collecting coins, avoiding debt and taxes, saving money, buying gear, and playing arcade-style levels.

The actual Unity project is in `Unity_MoneyMuncher`.

The kids website for `moneymuncher.ca/kids` is in `Website/kids`.

## Files

- `Docs/MoneyMuncherDesign.md`: concept, core loop, online roadmap, and milestones.
- `Docs/MoneyMuncherKidsLaunch.md`: kids-web launch checklist.
- `Docs/GitHubPagesDeployment.md`: GitHub Pages setup for `moneymuncher.ca`.
- `Unity_MoneyMuncher/Assets/Scripts`: gameplay scripts.
- `Unity_MoneyMuncher/Assets/Editor`: Unity menu builders for campaign levels and WebGL.
- `Website/kids`: kids landing page, parent guide, privacy page, and WebGL hosting folder.

## Unity Setup

1. Open `Unity_MoneyMuncher` in Unity Hub as a Unity project.
2. Let Unity generate the missing local `Library` files and compile scripts.
3. In the Unity top menu, click `Money Muncher > Build Campaign Levels`.
4. Open `Assets/Scenes/MoneyMuncherTreasureIsland.unity`.
5. Press Play.

If your Unity version is different from `2022.3.50f1`, Unity may ask to upgrade or reserialize the project. That is okay for this prototype.

Controls:

- `WASD` or arrow keys to move.
- In Level 1, press `1` through `6` to switch characters.
- Eat coins, emeralds, treasures, trophies, and useful power-ups.
- Avoid debt, tax traps, cursed items, and red cards.
- At the end of Level 1, buy Speed Shoes or Magnet Gear, then go to Level 2.

## Prototype Goal

Get a two-level WebGL campaign playable:

- Level 1: Treasure Island money basics.
- Level 2: Soccer Stadium arcade challenge.
- End-of-level gear shop.
- Local saved coins and gear.
- Privacy-safe kids web launch.

After that, the best next step is game feel: chomp animation, particles, pickup trails, sounds, and juicy score popups.

## Publishing Direction

The first public target is a Unity WebGL build on `moneymuncher.ca/kids`. See `Docs/MoneyMuncherKidsLaunch.md` and `Docs/GitHubPagesDeployment.md`.
