# Money Muncher iOS MVP

This folder contains a lightweight iOS app shell for Money Muncher. It is built as a native SwiftUI app that opens first-party Money Muncher experiences inside controlled `WKWebView` screens.

## What The MVP Includes

- Native SwiftUI home screen for kids and families.
- Fast launch actions for Cup Rush and Everyday Quest Generator.
- Parent gate before account setup and parent-guide screens.
- First-party navigation restriction for `moneymuncher.ca`.
- In-app content rules that block Google Tag Manager and Google Analytics requests inside the iOS app web views.
- Apple privacy manifest with no native SDK data collection declared.

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

1. In Xcode, choose **Any iOS Device**.
2. Select **Product > Archive**.
3. In Organizer, validate the archive.
4. Distribute to App Store Connect.
5. Add the build to TestFlight for internal testing.

## App Review Notes

This project is intentionally not just a blank website wrapper. The first screen is native, family areas are parent-gated, and web navigation is limited to the Money Muncher domain.

Before submitting in the Kids Category, review whether the embedded web pages should keep third-party web analytics. The app currently blocks Google Tag Manager and Google Analytics inside `WKWebView`, but the App Store privacy questionnaire should still match the real production behavior.

## Recommended Next App-Only Polish

- Add native saved quests for offline family play.
- Add iPad landscape layout checks for Cup Rush.
- Add custom screenshots and a final App Store icon set.
- Add a short native onboarding screen for parents.
- Add crash reporting only if it is privacy-reviewed for children.
