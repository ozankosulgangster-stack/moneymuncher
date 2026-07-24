# App Review Response — Version 1.0 (Build 9)

Submission ID: `a16d0f5f-4fa2-4c51-8555-9d07dc4b1167`

> Paste this response only after completing the build-9 device test, adding the demo account in App Review Information, and replacing every promotional screenshot listed in the checklist.

Hello App Review,

Thank you for the additional review. We addressed both remaining issues.

## Guideline 2.1(a) — Sign In on iPad

We identified two iPad presentation issues. The app previously attempted to present the account experience before the parent-gate sheet had finished dismissing, and then displayed the web account form inside a short form sheet that could hide its actions behind the keyboard. Build 9 waits for the parent gate to dismiss completely and presents the web experience full screen.

We also made the account flow more explicit and resilient:

- **Account & Data** opens the sign-in dialog directly.
- The direct Sign In form contains only email, password, and the relevant account actions.
- The web experience uses the full iPad screen, supports interactive keyboard dismissal, and keeps constrained forms scrollable.
- Sign-in feedback appears above the action buttons and remains visible while the keyboard is present.
- Sign In and Sign Up use larger iPad touch targets.
- Tapping Sign In immediately displays **Signing in…** and disables duplicate actions.
- Missing credentials, incorrect credentials, network failure, and timeout states appear inside the dialog.
- The account page and its scripts use build-9 cache identifiers.

Review path:

1. Open **Family Area > Account & Data**.
2. At **Parent Check**, enter `13` and tap **Unlock**.
3. Wait for the account sheet to open automatically.
4. Enter the review credentials supplied in App Review Information and tap **Sign In**.

The flow was tested from a clean install using the Release configuration on:

- `[ADD EXACT iPAD MODEL AND iPADOS VERSION]`
- `[ADD EXACT iPHONE MODEL AND iOS VERSION]`

## Guideline 2.3.3 — Accurate Metadata

We removed the promotional images that did not show the actual app interface. The replacement screenshots were captured from build 9 and show Money Muncher in active use, including:

- the native Money Muncher mission home
- active Cup Rush gameplay
- a generated Everyday Quest with its choices
- the Money World map and an active learning scenario

The iPhone and iPad screenshot sets now use actual in-app screens throughout and accurately represent the submitted binary.

Thank you for reviewing Money Muncher build 9.
