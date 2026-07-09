# Money Muncher iOS Publishing Plan

## Recommendation

Ship the first iOS version as a native SwiftUI app shell around the strongest live Money Muncher experiences:

- Cup Rush game
- Everyday Quest Generator
- family signup
- parent guide
- privacy page

This creates a faster path to TestFlight than a full Unity iOS build, while still avoiding the feel of a plain website wrapper.

## Why This Path

The current repo already has polished web and Unity WebGL content. A native SwiftUI shell lets us publish quickly, add parent controls, and keep the live website as the content source. A full Unity iOS build can come later when the game loop, assets, sound, and mobile controls are ready for a deeper app experience.

## Current iOS MVP

The iOS project lives at:

```text
ios/MoneyMuncher/MoneyMuncher.xcodeproj
```

It includes:

- native home screen
- first-party `WKWebView` experiences
- parent gate for family/account areas
- blocked Google Tag Manager and Google Analytics requests inside the app web views
- privacy manifest
- App Store submission draft

## Mac/Xcode Steps

1. Activate the Apple Developer account.
2. Open `ios/MoneyMuncher/MoneyMuncher.xcodeproj` in Xcode.
3. Select the `MoneyMuncher` target.
4. Set the signing team.
5. Confirm or adjust bundle identifier `ca.moneymuncher.app`.
6. Run on simulator.
7. Run on a real iPhone or iPad.
8. Archive and upload to App Store Connect.
9. Add the build to TestFlight.
10. Submit for App Review after metadata and privacy answers are complete.

## App Store Positioning

Use a family learning angle:

```text
Money quests for kids and families.
```

Avoid claiming investment advice, real trading, or financial product recommendations. Market Lab and any investing-style features should be described as virtual learning only.

## Kids And Privacy Notes

If submitting in the Kids Category, keep the standard very high:

- no third-party ads
- no behavioral tracking
- parent gate before account setup, external links, or grown-up content
- privacy policy must be clear about Firebase/account data
- app behavior must match App Store privacy answers

The native app blocks Google Tag Manager and Google Analytics inside its web views. If Apple review needs an even cleaner version, create app-specific pages under `moneymuncher.ca/app/` without third-party analytics scripts.

## Later Upgrade Path

After the iOS MVP is accepted:

1. Add native saved family quests.
2. Add sound, haptics, and offline reward badges.
3. Build a Unity iOS target for Cup Rush if the game becomes the main app.
4. Add deeper parental dashboard features.
