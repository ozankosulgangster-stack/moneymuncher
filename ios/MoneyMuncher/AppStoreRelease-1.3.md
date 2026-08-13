# Money Muncher 1.3 — App Store Submission Copy

## What’s New

Meet the new Money Muncher family experience!

- Build your family crew with parent-managed child profiles.
- Create shared savings goals and watch progress grow together.
- Record family contributions, gift-pool gifts, round-ups, and found-money wins.
- Add private weekly or inactivity reminders to keep goals moving.
- Turn everyday family moments into shared quests and activities.
- Explore character-led Dino Money Lab lessons about saving, cards, interest, and investing basics.
- Enjoy a completely refreshed home screen with animated characters, clearer adventures, family progress, and more celebrations.
- Try a lightweight 60-second Money Mission through the new App Clip, with no sign-in required.
- Discover the redesigned Money Muncher Plus experience, including Everyday Quests, premium lessons, and support for more than five child profiles.

Family profiles, activities, goals, and progress are saved locally on the device in this release. Family goal tools track progress only; Money Muncher does not connect to bank accounts or transfer money.

## Promotional Text

Turn everyday money moments into family adventures with shared goals, character-led lessons, fun quests, and progress worth celebrating.

## App Review Notes

Version 1.3 adds a native, parent-gated Family Community and refreshes the native SwiftUI landing and subscription experiences.

To review Family Community:

1. Open the app and select Family Community from the home screen.
2. Complete the parental gate.
3. Add a child profile. Up to five profiles are available without Plus; additional profiles require an active Money Muncher Plus entitlement.
4. Create a family goal, select participants, and record a contribution.
5. From the goal detail screen, test gift-pool recording, found-money additions, round-up tracking, progress celebrations, and Goal Updates.
6. Select Follow-up Reminder to configure a weekly or inactivity reminder. The test option schedules a local notification after approximately ten seconds.

Important implementation notes:

- Family profiles, shared activities, goals, contributions, and progress are stored locally on the device. They are not remote user accounts and do not sync between devices.
- Family goal contributions, gift pools, found-money entries, and round-ups are progress-tracking records only. The app does not connect to financial accounts, detect transactions, collect payments, or transfer funds.
- Goal reminders use Apple’s local UserNotifications APIs. Notification text intentionally omits child names, goal names, balances, and contribution amounts.
- Purchase options are protected by a parental gate and use StoreKit 2. Premium access is based on current App Store entitlements. Any introductory offer is presented by Apple only when the reviewing account is eligible.
- Cup Rush remains available without a Plus subscription. Everyday Quest, Dino Money Lab, and profiles beyond the free limit are Plus features.
- Investing lessons use virtual educational examples and do not enable trading or provide individualized financial advice.
- Web views restrict navigation to the first-party moneymuncher.ca domain and block Google Tag Manager and Google Analytics requests inside the iOS app.
- The App Clip provides three short money-choice questions, stores no personal information, offers no purchases, and uses Apple's App Clip overlay to present the full app after completion.

## Internal Release Checklist

- Marketing version: 1.3
- Build: 34
- Bundle identifier: ca.moneymuncher.app
- Minimum iOS version: 16.0
- Confirm the 1.3 App Store version record exists before attaching build 34.
- Confirm subscription products and introductory offers are Ready to Submit or approved.
- Confirm App Privacy answers match the production website and native app behavior.
- Attach build 34, paste the What’s New copy, add the review notes, and submit for review.
