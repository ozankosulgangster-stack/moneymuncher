# App Store Submission Report: Money Muncher 1.2 (27)

**Prepared:** August 5, 2026  
**Bundle ID:** `ca.moneymuncher.app`  
**App Store Connect App ID:** `6789588978`  
**Source commit:** `3c2d862` (`Add Mira and Captain Jack lessons`)

## Release Summary

Money Muncher 1.2 expands the Plus learning area with character-led financial-literacy stories for children and families.

- **Captain Jack's Card Cabin:** a shark-led visual story explaining debit cards, credit cards, statements, safe card habits, and loyalty-point choices.
- **Mira's Interest Garden:** a turtle-led visual story explaining saving interest, borrowing costs, APR, minimum payments, and compounding.
- **Sammy's Stock Slice Studio:** a unicorn-led lesson covering ownership, buying and selling, risk, and adult-guided investing basics.
- **Dino's Money Story:** includes debit, interest, and saving scenes. The interest scene now uses Mira and her recorded narration.
- **Money Muncher Plus:** native StoreKit 2 paywall with monthly and annual auto-renewable subscriptions, purchase handling, and Restore Purchases.

All examples use pretend money for education. The app does not provide brokerage access, real-money trading, investment recommendations, or financial advice.

## Customer-Facing “What’s New”

```text
Meet new money teachers in Money Muncher Plus.

Captain Jack helps kids understand debit, credit, loyalty points, and smart card habits. Mira makes interest, saving, APR, and borrowing easier to explore through her garden story. We also improved premium lesson access and recorded character narration.
```

## App Review Notes

Paste the following into **App Review Information > Notes**:

```text
Money Muncher is a family-friendly financial-literacy app for children and parents. The native iOS home screen includes free Cup Rush and Everyday Quest experiences, plus a parent-gated Money Muncher Plus area.

No login is required to review the app.

To review Money Muncher Plus:
1. Launch the app and tap “Money Muncher Plus” or “Dino Money Lab.”
2. Complete the parent check. The answer is 13.
3. Select Plus Monthly or Plus Annual to test the StoreKit purchase flow, then confirm premium access opens the learning hub.
4. Use “Restore Purchases” to test restoration.

Premium lessons use educational, pretend-money examples only. They do not enable investing, brokerage activity, or real-money trading. The card lesson explains debit, credit, statements, and loyalty points; the interest lesson explains saving interest, borrowing costs, APR, minimum payments, and compounding.

The app uses StoreKit 2 for subscriptions. No third-party advertising SDKs, analytics SDKs, microphone, camera, location, contacts, or health data are used by the native app.
```

## Subscription Submission

| Item | Value | Submission action |
| --- | --- | --- |
| Subscription group | Money Muncher Plus | Add the first group with this app version. |
| Monthly product | `ca.moneymuncher.app.plus.monthly` | Include in the version submission. |
| Annual product | `ca.moneymuncher.app.plus.annual` | Include in the version submission. |
| Entitlement behavior | Plus unlocks Everyday Quest and Dino Money Lab | Test purchase and restore on a real device. |
| Family Sharing | Optional product decision | Keep the App Store Connect setting aligned with the business plan. |

The product identifiers in the build exactly match the two identifiers above. Confirm both subscriptions have completed localization, price, availability, review screenshot, and required tax/banking agreements before submitting.

## Reviewer Test Path

1. Install `1.2 (27)` from TestFlight or the review build.
2. Confirm the home screen opens and free Kid Missions remain available.
3. Tap **Money Muncher Plus** and complete the parent check using `13`.
4. Confirm monthly and annual plans load from StoreKit.
5. Buy one subscription with a Sandbox account.
6. Confirm **Plus Active** appears, then open **Dino Money Lab**.
7. Open **Captain Jack's Card Cabin** and play Captain Jack’s recorded welcome.
8. Open **Mira's Interest Garden** and play Mira’s recorded welcome.
9. Open **Dino's Money Story**, select the interest scene, and confirm Mira is shown and her recording plays.
10. Relaunch the app, use **Restore Purchases**, and confirm Plus content remains available.

## Audio and Visual Scope

The build bundles recorded MP3 welcomes for Dino, Mira, Sammy, and Captain Jack. The character lesson routes use these recordings directly and do not switch to device text-to-speech when a recording is unavailable.

Mira’s recording is approximately 15 seconds and Captain Jack’s is approximately 12 seconds. Their remaining lesson cards are visual/text guided. Do not describe the lessons in App Store copy as fully voiced, fully animated video, or lip-synced content.

## Screenshot Plan

Upload real `1.2 (27)` screens only. Do not use a simulator-only unlock state, an unavailable-plans state, or a Sandbox sign-in alert.

| Order | Suggested file | Capture |
| --- | --- | --- |
| 1 | `MM_01_Home.png` | Native Money Muncher home, with Kid Missions and Family Area visible. |
| 2 | `MM_02_CupRush.png` | Cup Rush during clear gameplay. |
| 3 | `MM_03_EverydayQuest.png` | A complete Everyday Quest choice. |
| 4 | `MM_04_MiraInterestGarden.png` | Plus active, Mira’s Interest Garden with Mira visible. |
| 5 | `MM_05_CaptainJack.png` | Captain Jack’s Card Cabin with the character and card story visible. |
| 6 | `MM_06_Plus.png` | The live paywall with both monthly and annual plans loaded. |

Capture the same set on the supported iPhone and iPad device classes. Preserve the original PNG dimensions and avoid marketing overlays inside the screenshots.

## Privacy and Accessibility

### Verified Native-App Facts

- The privacy manifest declares no native data collection, no tracking, no tracking domains, and no required-reason API access.
- The native app does not request microphone, camera, location, contacts, or health permissions.
- The app links to `https://moneymuncher.ca/kids/privacy.html`.
- The native experience uses explicit accessibility labels for primary navigation, purchase access, and character lesson stages.

### Required Confirmation Before Submission

- Review the live first-party web pages opened inside the app. If family sign-up or web analytics collects data, the App Store privacy answers must disclose the full app behavior, not only the native Swift code.
- Do not opt into Accessibility Nutrition Labels until the complete purchase, lesson, and web flows have been audited on iPhone and iPad with the feature enabled.
- Do not claim captions, audio descriptions, reduce-motion support, or full VoiceOver support until the corresponding end-to-end audit is complete.

## Final App Store Connect Checklist

- [ ] Build `1.2 (27)` is selected for the version.
- [ ] Version number, description, keywords, support URL, and privacy policy URL are current.
- [ ] Both subscriptions are attached to the app version for review.
- [ ] Monthly and annual products show valid pricing, availability, localization, and review metadata.
- [ ] A live paywall screenshot is attached to the subscription review information.
- [ ] The Paid Apps Agreement, tax forms, and banking status are active.
- [ ] App Privacy answers match the native app and every first-party web experience it opens.
- [ ] Content-rights declaration covers the recorded narration and generated character artwork.
- [ ] Export-compliance answers are completed for the final archive.
- [ ] Purchase, cancellation, pending, restore, and premium-relaunch flows are tested on a real iPhone and iPad.
- [ ] The submission is sent with the first subscription group attached to this new app version.

## Release Risks to Resolve Before “Submit for Review”

1. **Subscription status:** the first subscription group must be submitted with the new app version. Do not submit the app version without attaching both products.
2. **Privacy declaration:** confirm the live web content does not collect data beyond the App Privacy answers.
3. **Accessibility claims:** keep unsupported Nutrition Labels unselected until the device audit is complete.
4. **Sandbox behavior:** the build keeps previously purchased Sandbox subscriptions available for beta testing after Sandbox renewal expiration. This is intentionally limited to the Sandbox environment; confirm this behavior is still desired before release review.
5. **Recording scope:** replace or add longer recordings only if the product requirement changes to fully narrated lessons. The current build is accurately described as recorded character welcomes plus visual/text lesson cards.
