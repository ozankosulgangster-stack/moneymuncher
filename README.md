# MoneyMuncher

A kid-friendly money learning game for `moneymuncher.ca`.

This repository now contains two tracks:

- The existing MoneyMuncher Alpha web prototype on `main`.
- A new Unity WebGL kids game prototype under `Unity_MoneyMuncher`, with a GitHub Pages-ready website package under `Website`.
- A lightweight iOS MVP shell under `ios/MoneyMuncher` for TestFlight and App Store preparation.

## Existing Alpha App

The original app includes:

- Kid-facing landing page
- Interactive financial choices game
- Stats: coins, saved, joy, wisdom
- Login with server-side user records
- Member-only Market Lab teaser on the homepage
- Market Lab at `/market-lab/` with Firebase-authenticated virtual stock/ETF simulation
- Money World Map with level nodes
- Locked/unlocked level progression saved to `data/db.json`
- 5 prototype levels:
  1. Snack Shop - needs vs wants
  2. Toy Market - impulse control
  3. Savings Bank - goals and patience
  4. Sharing Square - giving and community
  5. Family Budget - planning together
- Teacher / parent community hub concept
- Quest idea input prototype

Run locally:

```bash
npm start
```

Then open:

```text
http://127.0.0.1:4173
```

Market Lab:

```text
http://127.0.0.1:4173/market-lab/
```

Market Lab saves virtual portfolio data in Firestore under:

```text
players/{uid}/marketLab/portfolio
```

It uses virtual coins only. It does not place trades, connect to a brokerage, or provide financial advice.

## Unity Kids Game

Money Muncher Unity is a WebGL arcade game about collecting coins, avoiding debt and taxes, saving money, buying gear, and playing arcade-style levels.

The Unity project is in:

```text
Unity_MoneyMuncher
```

The kids website for GitHub Pages is in:

```text
Website/kids
```

Unity flow:

1. Open `Unity_MoneyMuncher` in Unity Hub.
2. In Unity, click `Money Muncher > Build Campaign Levels`.
3. Open `Assets/Scenes/MoneyMuncherTreasureIsland.unity`.
4. Press Play.

Controls:

- `WASD` or arrow keys to move.
- In Level 1, press `1` through `6` to switch characters.
- Eat coins, emeralds, treasures, trophies, and useful power-ups.
- Avoid debt, tax traps, cursed items, and red cards.
- At the end of Level 1, buy Speed Shoes or Magnet Gear, then go to Level 2.

## Publishing

The first public Unity target is a WebGL build on:

```text
https://moneymuncher.ca/kids
```

Build steps:

1. In Unity, click `Money Muncher > Build Campaign Levels`.
2. In Unity, click `Money Muncher > Build Kids WebGL`.
3. Commit the generated WebGL files under `Website/kids/play`.
4. Push to `main`.
5. GitHub Actions deploys the `Website` folder through GitHub Pages.

See:

- `Docs/MoneyMuncherKidsLaunch.md`
- `Docs/GitHubPagesDeployment.md`

## iOS MVP

The first iOS publishing path is a native SwiftUI shell around the live Money Muncher experiences, with parent-gated family areas and first-party web navigation.

Open on a Mac:

```text
ios/MoneyMuncher/MoneyMuncher.xcodeproj
```

See:

- `Docs/iOSPublishingPlan.md`
- `ios/MoneyMuncher/APP_STORE_SUBMISSION.md`
