# Money Muncher App Clip — 1.3

## Default App Clip Experience

- Invocation URL: `https://www.moneymuncher.ca/appclip?mission=save`
- Subtitle: `Play a 60-second money mission.`
- Action: `PLAY`
- Header image: `MoneyMuncher-AppClip-Header-1800x1200.png`
- App Clip bundle ID: `ca.moneymuncher.app.Clip`

## App Review Notes

The Money Muncher App Clip is a lightweight, native SwiftUI preview of the full app's Everyday Quest learning experience. It presents three short, age-appropriate money choices and immediate educational feedback. It does not require an account, offer purchases, connect to financial accounts, collect personal data, or transfer money.

After completing the mission, the Apple-provided StoreKit App Clip overlay allows the reviewer to view the full Money Muncher app. The clip supports the invocation URL above and reads the optional `mission` query value only to personalize the hero label.

To test locally in Xcode, run the `MoneyMuncherClip` scheme and set `_XCAppClipURL` to:

`https://www.moneymuncher.ca/appclip?mission=save`

## Required Apple Developer Configuration

1. Register the App Clip identifier `ca.moneymuncher.app.Clip` under the existing parent app identifier `ca.moneymuncher.app`.
2. Enable App Clips and Associated Domains for the applicable identifiers.
3. Refresh the main app's App Store provisioning profile and allow Xcode to create the App Clip profile.
4. Deploy `/.well-known/apple-app-site-association` to `https://www.moneymuncher.ca/.well-known/apple-app-site-association` with the `application/json` content type and no redirect. Use the `www` host because the bare domain redirects.
5. Upload the containing Money Muncher build before entering the App Clip metadata in App Store Connect.
