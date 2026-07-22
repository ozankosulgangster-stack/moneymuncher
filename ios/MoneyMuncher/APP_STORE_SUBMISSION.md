# App Store Submission Draft

## App Identity

- App name: Money Muncher
- Version: `1.0 (2)`
- Subtitle: Money quests for kids and families
- Bundle ID: `ca.moneymuncher.app`
- SKU: `moneymuncher-ios`
- App Store Connect app ID: `6789588978`
- Primary language: English (Canada)
- Primary category: Education
- Secondary category: Games
- Suggested age rating: 4+ or Kids Category after final privacy review

## Short Description

Money Muncher turns everyday family choices into playful money missions. Kids can collect coins, dodge debt, and practice saving, spending, and giving through quick game-like experiences.

## Promotional Text

Kick off Cup Rush, try an Everyday Quest, and make money conversations easier at home.

## Keywords

kids money, financial literacy, allowance, saving, budgeting, family learning, education game

## Support URLs

- Marketing URL: `https://moneymuncher.ca/`
- Support URL: `https://moneymuncher.ca/support.html`
- Privacy Policy URL: `https://moneymuncher.ca/kids/privacy.html`

## Demo Account

If review needs an account, create a test family login before submission and include it in App Review notes. Do not use a personal account.

## Review Notes

Money Muncher is a family-friendly financial education app. The native iOS home screen offers quick access to kid missions and parent resources. Account setup and parent guidance are protected with a parent gate. The app restricts in-app web navigation to Money Muncher first-party pages.

The app uses no native advertising SDKs, no in-app purchases, and no brokerage or real-money trading features. Learning experiences use virtual coins only.

### Guideline 4.7 content index

1. **Money Muncher Cup Rush**
   - Developer: Money Muncher
   - URL: `https://moneymuncher.ca/kids/play/`
   - Type: Educational Unity WebGL mini game
   - Description: Players collect virtual coins, avoid debt obstacles, and answer financial-literacy gates.
   - Monetization: None; no purchases, advertising, or real-money activity.
2. **Everyday Quest Generator**
   - Developer: Money Muncher
   - URL: `https://moneymuncher.ca/kids/#questGeneratorTitle`
   - Type: Educational interactive software
   - Description: Generates short family financial-literacy scenarios and choices.
   - Monetization: None; no purchases, advertising, or real-money activity.
3. **Money Muncher Learning Hub**
   - Developer: Money Muncher
   - URL: `https://moneymuncher.ca/`
   - Type: Interactive financial-literacy learning software
   - Description: Guided quests, a learning map, lessons, quizzes, and parent/teacher activities.
   - Monetization: None; no purchases, advertising, or real-money activity.
4. **Money Muncher Market Lab**
   - Developer: Money Muncher
   - URL: `https://moneymuncher.ca/market-lab/`
   - Type: Educational virtual-market simulator
   - Description: Simulated stock and ETF portfolio learning with virtual coins only.
   - Monetization: None; no brokerage activity or real-money trading.
5. **Money Muncher Classroom Market**
   - Developer: Money Muncher
   - URL: `https://moneymuncher.ca/kids/classroom-market/`
   - Type: Educational browser game
   - Description: Players compare price, quality, value, and need using virtual classroom coins.
   - Monetization: None; no purchases, advertising, or real-money activity.
6. **Money Muncher Badge Shop**
   - Developer: Money Muncher
   - URL: `https://moneymuncher.ca/kids/rewards/`
   - Type: Interactive educational rewards software
   - Description: Players use virtual practice coins for learning badges and review virtual coin history.
   - Monetization: None; rewards have no cash value and cannot be purchased.

Public index with complete metadata: `https://moneymuncher.ca/app-review/`

### Account deletion review path

1. From the native home screen, open **Family Area > Family Sign Up** and complete account creation, or sign in with the review account.
2. Return to the native home screen and open **Family Area > Account & Data**.
3. On the account page, select **Delete account**.
4. Review the permanent-deletion explanation and select **Delete permanently**.
5. The Firebase Authentication account, its `players/{userId}` cloud profile/progress document, and its Market Lab portfolio document are permanently deleted.

Attach a physical-device screen recording demonstrating the full flow in App Review Information > Notes.

## Screenshots Needed

- iPhone 6.7-inch: native home, Cup Rush, Everyday Quest, parent gate.
- iPhone 6.5-inch or 6.1-inch: same set if App Store Connect requests it.
- iPad 13-inch: native home and Cup Rush landscape.

## Privacy Questionnaire Prep

Confirm the final answer set before submission:

- Email address: collected if family signup remains enabled.
- User ID: collected if Firebase account creation remains enabled.
- Gameplay/progress data: collected if saved progress remains enabled.
- Purchases: not collected.
- Financial information: not collected.
- Tracking: no, if the iOS app continues to block third-party analytics and no cross-app tracking SDK is added.
- Ads: no.

## Pre-Submission Checklist

- Apple Developer Program membership is active.
- App Store Connect app record exists for app ID `6789588978`.
- Bundle ID `ca.moneymuncher.app` is registered and assigned to the app record.
- Signing team `A2TAG4GHM2` is selected in Xcode.
- App icon is opaque and has no alpha channel.
- TestFlight upload requires Xcode 26 or later because App Store Connect rejects iOS 18.4 SDK uploads.
- Privacy policy is live and accurate.
- Support URL is live.
- Parent gate is tested.
- TestFlight build is tested on real iPhone and iPad.
- App Review demo account is created if account access is required.
- App Store privacy answers match the production app behavior.
