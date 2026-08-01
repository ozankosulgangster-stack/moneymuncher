# App Store Submission Draft

## App Identity

- App name: Money Muncher
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
- Support URL: `https://moneymuncher.ca/kids/parent-guide.html`
- Privacy Policy URL: `https://moneymuncher.ca/kids/privacy.html`

## Demo Account

If review needs an account, create a test family login before submission and include it in App Review notes. Do not use a personal account. For subscription review, include a Sandbox Apple Account if App Review asks for one.

## Review Notes

Money Muncher is a family-friendly financial education app. The native iOS home screen offers quick access to kid missions and parent resources. Account setup, parent guidance, and Money Muncher Plus purchase options are protected with a parent gate. The app restricts in-app web navigation to Money Muncher first-party pages.

The app uses no native advertising SDKs and no brokerage or real-money trading features. Learning experiences use virtual coins and virtual examples only. Money Muncher Plus uses native Apple in-app purchases through StoreKit 2 and includes restore purchases.

## In-App Purchase Setup

- Subscription group: `Money Muncher Plus`
- Monthly product ID: `ca.moneymuncher.app.plus.monthly`
- Annual product ID: `ca.moneymuncher.app.plus.annual`
- First paid features in MVP: `Everyday Quest` and `Dino Money Lab`
- Premium learning modules: `Card Captain`, `Interest Lab`, and `Stock Slice Studio`
- Required review evidence: paywall screenshot, parent gate screenshot, premium module screenshot, subscription metadata, privacy policy URL, restore purchase flow.

## Screenshots Needed

- iPhone 6.7-inch: native home, Cup Rush, Everyday Quest, parent gate.
- iPhone 6.5-inch or 6.1-inch: same set if App Store Connect requests it.
- iPad 13-inch: native home and Cup Rush landscape.

## Privacy Questionnaire Prep

Confirm the final answer set before submission:

- Email address: collected if family signup remains enabled.
- User ID: collected if Firebase account creation remains enabled.
- Gameplay/progress data: collected if saved progress remains enabled.
- Purchases: review final answer after deciding whether StoreKit entitlement data stays on-device only or is synced to Firebase accounts.
- Financial information: not collected.
- Tracking: no, if the iOS app continues to block third-party analytics and no cross-app tracking SDK is added.
- Ads: no.

## Pre-Submission Checklist

- Apple Developer Program membership is active.
- App Store Connect app record exists for app ID `6789588978`.
- Bundle ID `ca.moneymuncher.app` is registered and assigned to the app record.
- Signing team `A2TAG4GHM2` is selected in Xcode.
- App icon is opaque and has no alpha channel.
- Money Muncher Plus subscription group and products are created in App Store Connect.
- StoreKit purchase, cancel, pending approval, and restore flows are tested with a Sandbox Apple Account.
- TestFlight upload requires Xcode 26 or later because App Store Connect rejects iOS 18.4 SDK uploads.
- Privacy policy is live and accurate.
- Support URL is live.
- Parent gate is tested.
- TestFlight build is tested on real iPhone and iPad.
- App Review demo account is created if account access is required.
- App Store privacy answers match the production app behavior.
