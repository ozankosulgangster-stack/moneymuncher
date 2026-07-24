# Build 8 App Review Checklist

Do not resubmit until every item below is complete.

## 1. Deploy the account-page hotfix

- Deploy the build 8 versions of `index.html`, `app.js`, and `styles.css` to `moneymuncher.ca` before archiving the iOS app.
- Open `https://moneymuncher.ca/?source=ios-app&action=signin&reviewBuild=8#account` in Safari.
- Confirm the account dialog opens automatically and shows the green review-account instruction above the Sign In button.
- Confirm the deployed page loads `app.js?v=8` and `styles.css?v=8`, rather than a cached build 6 asset.

## 2. Verify sign in from a clean install

- Archive and upload **version 1.0 (build 8)**.
- Delete Money Muncher from the test iPad before installing the TestFlight build.
- Test on an iPad, ideally the **iPad Air 11-inch (M3)** used by App Review.
- Open **Family Area > Account & Data**.
- Enter `13` in the parent gate and tap **Unlock**.
- Confirm the parent gate dismisses and the account sheet opens automatically.
- Confirm the green instruction/status panel is visible above the buttons.
- Test empty fields, incorrect credentials, correct credentials, and Return/Go on the keyboard.
- Repeat once by installing build 8 as an update over build 6.
- Record the exact devices and OS versions in `APP_REVIEW_RESPONSE_1.0.md`.

## 3. Supply a working review account

- Create a dedicated, verified family review account.
- Test the credentials immediately before submission.
- Add the email and password to **App Store Connect > App Review Information > Sign-in required**.
- Do not commit the credentials to this repository or include them in public notes.

## 4. Replace the rejected screenshots

Open **App Store Connect > version 1.0 > App Previews and Screenshots > View All Sizes in Media Manager**.

Delete the existing dinosaur/promotional images. They describe features and show a fabricated phone UI rather than the submitted app, which caused the Guideline 2.3.3 rejection.

Upload four or five real screenshots captured from the Release/TestFlight build:

1. Native home screen showing Kid Missions and Family Area.
2. Cup Rush during active gameplay, with the touch controls visible.
3. Everyday Quest after generating a quest, with choices visible.
4. Money World map or an active scenario with choices.
5. Optional: Academy lesson or Classroom Market during use.

Do not use the splash screen, login screen, parent gate, standalone mascot artwork, or promotional art as the majority of either screenshot set. Small text overlays are allowed, but the actual app interface must remain the dominant content.

Preferred upload sizes:

- iPhone 6.9-inch: `1290 × 2796` portrait, or another accepted 6.9-inch size.
- iPhone 6.5-inch fallback: `1284 × 2778` portrait.
- iPad 13-inch: `2064 × 2752` portrait.

Use PNG or JPEG without transparency. Confirm the images are sharp, contain no test credentials, and match build 8.

## 5. Final App Store Connect pass

- Select build 8 for version 1.0.
- Confirm the Support URL and Privacy Policy URL still load.
- Confirm the demo account is present and working.
- Paste the completed response from `APP_REVIEW_RESPONSE_1.0.md`.
- Attach a short iPad screen recording of parent gate → account sheet → successful sign in if App Review Information permits an attachment.
- Submit only after testing the exact TestFlight binary selected for review.
