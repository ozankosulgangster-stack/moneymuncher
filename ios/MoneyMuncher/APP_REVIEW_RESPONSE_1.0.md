# App Review Response — Version 1.0

Submission ID: `2f926406-16f9-4296-8d48-c5e7eb0a8704`

Thank you for reviewing Money Muncher. We addressed each item as follows:

## Guideline 1.5 — Support URL

The Support URL has been updated to `https://moneymuncher.ca/support.html`. The page provides a functional support-request form, problem-reporting guidance, account-deletion instructions, troubleshooting information, and a privacy-policy link.

## Guideline 5.1.1(v) — Account deletion

Signed-in users can now initiate and complete permanent account deletion in the app. From the native home screen, choose **Family Area > Account & Data**, sign in if needed, choose **Delete account**, and confirm **Delete permanently**. This deletes the Firebase Authentication account, its cloud-saved profile/progress document, and its Market Lab portfolio document. A physical-device recording of account creation/sign-in and the complete deletion flow is attached in App Review Information > Notes.

## Guideline 4.7.4 — Non-embedded software index

1. Money Muncher Cup Rush
   - Developer: Money Muncher
   - URL: `https://moneymuncher.ca/kids/play/`
   - Educational Unity WebGL mini game in which players collect virtual coins, avoid debt obstacles, and answer financial-literacy gates.
   - No purchases, advertising, or real-money activity.
2. Everyday Quest Generator
   - Developer: Money Muncher
   - URL: `https://moneymuncher.ca/kids/#questGeneratorTitle`
   - Interactive educational software that generates short family financial-literacy scenarios and choices.
   - No purchases, advertising, or real-money activity.

Both experiences are developed and published by Money Muncher and are served from the first-party `moneymuncher.ca` domain.

## Guideline 2.1(a) — Cup Rush responsiveness

Cup Rush previously relied on keyboard-only Unity movement input. We added visible touch movement controls for iPhone and iPad, prevented page scrolling from intercepting game gestures, focused the Unity canvas when controls are used, and reduced the mobile WebGL rendering pixel ratio for improved responsiveness. The loading and full play flow have been retested on supported form factors.
