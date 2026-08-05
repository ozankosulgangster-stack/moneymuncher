# Money Muncher iOS MVP

This folder contains a lightweight iOS app shell for Money Muncher. It is built as a native SwiftUI app that opens first-party Money Muncher experiences inside controlled `WKWebView` screens.

## What The MVP Includes

- Native SwiftUI home screen for kids and families.
- Fast launch actions for Cup Rush and Everyday Quest Generator.
- Parent gate before account setup and parent-guide screens.
- Native StoreKit 2 paywall for Money Muncher Plus.
- Parent gate before purchase options are shown.
- Premium unlock checks using current App Store entitlements.
- Dino Money Lab premium modules for cards, interest, and stock-market basics.
- Built-in audio narration for Dino lesson steps using iOS text-to-speech, plus recorded Ollie narration for the interest story.
- First-party navigation restriction for `moneymuncher.ca`.
- In-app content rules that block Google Tag Manager and Google Analytics requests inside the iOS app web views.
- Apple privacy manifest with no native SDK data collection declared.

## Money Muncher Plus Paywall

The iOS app now has a native StoreKit 2 paywall. For the first MVP slice, `Everyday Quest` is treated as the first Plus feature while `Cup Rush` remains free.

Plus content currently includes:

- `Everyday Quest`
- `Dino Money Lab`
- `Card Captain`: credit cards, debit cards, and safe card habits.
- `Interest Lab`: borrowing costs, APR, minimum payments, and compounding.
- `Stock Slice Studio`: stock ownership, trades, risk, and diversification.
- Audio lesson controls on each Dino lesson step.

Investing lessons use virtual examples only and do not provide real-money trading advice.

Audio lessons use `AVSpeechSynthesizer` with the device's built-in text-to-speech voices. The Ollie interest story also includes the bundled `Narrations/ollie-interest.mp3` recording, which does not require a microphone permission or cloud service.

Subscription product IDs live in:

```text
MoneyMuncher/SubscriptionProducts.swift
```

Current IDs:

```text
ca.moneymuncher.app.plus.monthly
ca.moneymuncher.app.plus.annual
```

Before TestFlight purchase testing:

1. In App Store Connect, create one auto-renewable subscription group named `Money Muncher Plus`.
2. Add monthly and annual subscriptions using the product IDs above.
3. Add localized names, descriptions, prices, review screenshot, and subscription review notes.
4. Confirm the bundle ID `ca.moneymuncher.app` is enabled for in-app purchases.
5. Test purchase, cancel, pending purchase, and restore flows with a Sandbox Apple Account.

Until those products exist in App Store Connect or a local StoreKit configuration, the paywall will show a "Plans are not available yet" state.

Debug simulator builds include an `Unlock Plus in Simulator` button on the paywall so premium flows can be reviewed before StoreKit products are live. This button is compiled only for Debug simulator builds and is not included in device Release/TestFlight archives.

For the Firebase phase, keep StoreKit as the source of truth on iOS and sync entitlement state to Firebase only after we add accounts and server-side receipt/App Store Server Notification handling.

## Open In Xcode

1. On a Mac, open:

   ```text
   ios/MoneyMuncher/MoneyMuncher.xcodeproj
   ```

2. In Xcode, select the `MoneyMuncher` target.
3. Set **Signing & Capabilities > Team** to your Apple Developer team.
4. Confirm the bundle identifier is available:

   ```text
   ca.moneymuncher.app
   ```

5. Run on an iPhone simulator, then on a real iPhone or iPad.

## Build For TestFlight

App Store Connect requires uploads to be built with Xcode 26 or later. Xcode 16.3 can build the app locally, but App Store Connect rejects uploads built with the iOS 18.4 SDK.

1. In Xcode, choose **Any iOS Device**.
2. Select **Product > Archive**.
3. In Organizer, validate the archive.
4. Distribute to App Store Connect.
5. Add the build to TestFlight for internal testing.

For a repeatable command-line upload after the signing team is selected:

```bash
xcodebuild archive \
  -project MoneyMuncher.xcodeproj \
  -scheme MoneyMuncher \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath build/MoneyMuncher.xcarchive \
  -allowProvisioningUpdates

xcodebuild -exportArchive \
  -archivePath build/MoneyMuncher.xcarchive \
  -exportPath build/TestFlight \
  -exportOptionsPlist ExportOptions-TestFlight.plist \
  -allowProvisioningUpdates
```

## App Review Notes

This project is intentionally not just a blank website wrapper. The first screen is native, family areas and purchase options are parent-gated, and web navigation is limited to the Money Muncher domain.

Before submitting in the Kids Category, review whether the embedded web pages should keep third-party web analytics. The app currently blocks Google Tag Manager and Google Analytics inside `WKWebView`, but the App Store privacy questionnaire should still match the real production behavior.

## Recommended Next App-Only Polish

- Add native saved quests for offline family play.
- Add iPad landscape layout checks for Cup Rush.
- Add custom screenshots and a final App Store icon set.
- Add a short native onboarding screen for parents.
- Add crash reporting only if it is privacy-reviewed for children.
