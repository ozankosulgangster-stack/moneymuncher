# Money Muncher 1.3 — iPad App Store screenshots

Upload the five numbered JPEG files in `ipad-13-landscape` to the 13-inch iPad landscape screenshot slot in App Store Connect. Upload the three numbered JPEG files in `iphone-6.9-portrait` to the 6.9-inch iPhone portrait slot.

- iPad final size: 2752 × 2064 px
- iPhone final size: 1320 × 2868 px
- Format: high-quality JPEG, opaque/no alpha channel
- Source captures: real 11-inch iPad/TestFlight tests at 2266 × 1488 px
- iPhone source captures: real iPhone/TestFlight tests at 1170 × 2532 px
- Apple reference: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications

The tested app UI is preserved. Submission cleanup is limited to cropping the TestFlight/status-bar strip, replacing the throwaway test child name with `Kid profile`, and removing the transient Siri orb from one capture. The surrounding background and feature headings are marketing presentation layers.

The reusable renderers are `tools/build_ipad_store_screenshots.swift` and `tools/build_iphone_store_screenshots.swift`.
