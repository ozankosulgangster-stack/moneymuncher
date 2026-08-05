# App Store Marketing Pack: 1.2 (23)

Use this pack after the `1.2 (23)` TestFlight build has been tested on both iPhone and iPad. Capture real app screens only. Do not use the TestFlight paywall state that says plans are unavailable, the simulator-only unlock button, or a screenshot with a Sandbox sign-in alert.

## Required Screenshot Sets

Apple accepts one to ten PNG or JPEG screenshots per device family, with no alpha channel. The practical minimum for Money Muncher is one iPhone 6.9-inch set and one iPad 13-inch set because the app supports both platforms.

| Device | Simulator to use | Portrait export size |
| --- | --- | --- |
| iPhone | iPhone 16 Pro Max | 1320 x 2868 px |
| iPad | iPad Air 13-inch (M4) | 2064 x 2752 px |

Apple may scale these screenshots for smaller compatible device sizes. Use the simulator's native screenshot command and do not resize, crop, add transparency, or include a device frame in the uploaded file.

## Screenshot Storyboard

Capture the same five screens on iPhone and iPad, in this order.

| File name | Screen to capture | Suggested marketing headline |
| --- | --- | --- |
| `MM_01_Home.png` | Native home screen, with Kid Missions and Family Area visible. | Money skills start at home. |
| `MM_02_CupRush.png` | Cup Rush after tapping Kick Off, while gameplay is clear. | Play through everyday money choices. |
| `MM_03_EverydayQuest.png` | An Everyday Quest prompt with a complete choice visible. | Turn real moments into money missions. |
| `MM_04_DinoStory.png` | Plus active, Dino Money Lab, then Scene 2 playing with Ollie and the interest visual visible. | Stories that make money concepts click. |
| `MM_05_Plus.png` | The live Money Muncher Plus screen with loaded monthly and annual plans. | Keep learning with Money Muncher Plus. |

Keep any marketing headline outside the app screenshot in a simple opaque layout. It must describe the shown screen exactly. Do not claim investment returns, real trading, financial advice, or a feature that is not in the current build.

## Capture Steps

1. Upload `1.2 (23)` to TestFlight and install it on the device or simulator used for the capture.
2. Confirm the Plus entitlement is active before capturing the Dino story and Plus screen.
3. For the Dino story, open `Dino Money Lab`, choose `Dino's Money Story`, select Scene 2, and wait until Ollie is speaking and the interest visual is visible.
4. Capture with the native screenshot control. On Simulator, choose `File > Save Screen`. On a physical device, use the system screenshot buttons and transfer the original PNG without editing it.
5. Open each image in Preview and confirm the exact pixel dimensions in the table above. Export as a nontransparent PNG only if the original device size is accepted.
6. In App Store Connect, open the new iOS version, select the iPhone or iPad screenshot tab, and upload the files in the storyboard order.

Apple permits one to ten screenshots and optional previews. If the user interface is identical across other size classes, its Media Manager can scale the highest-resolution set for compatible devices. See Apple's [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) and [upload instructions](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/).

## Accessibility Nutrition Labels

In App Store Connect, use the Accessibility section for both iPhone and iPad, and set the Accessibility URL to:

```text
https://moneymuncher.ca/kids/accessibility.html
```

For this build, leave every Accessibility Nutrition Label unselected until the device audit below is completed. This is intentional: the current app uses standard SwiftUI controls and several explicit VoiceOver labels, but Apple requires a user to complete every common task with a feature before that feature can be declared.

Do not declare these features for `1.2 (23)` yet:

- Larger Text: several headings and story elements use fixed point sizes and have not been tested at the largest accessibility sizes.
- Reduced Motion: the Dino and Ollie stories contain motion that has not yet been audited against the system Reduce Motion setting.
- Captions: the story has written lesson text, but it is not a complete time-synchronized caption track.
- Audio Descriptions: the visual story does not provide a separate time-synchronized audio-description track.
- VoiceOver, Voice Control, Dark Interface, Differentiate Without Color Alone, and Sufficient Contrast: assess them on both devices before making a public claim.

Apple's labels appear on product pages for iOS 26 and later. The declaration is a product promise, not a checklist of partial support. See Apple's [Accessibility Nutrition Labels overview](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/).

## Device Audit Before Declaring Support

Run these tasks on both iPhone and iPad with each candidate system feature enabled:

1. Open the home screen and launch Cup Rush and Everyday Quest.
2. Complete the parent gate, then open the paywall and use Restore Purchases.
3. Open Dino Money Lab, play and stop the Ollie interest story, and switch scenes.
4. Read a lesson step, replay its audio, move between steps, and answer a Dino Check question.
5. Return to the home screen and open the Privacy screen.

For VoiceOver, confirm every control is announced with a useful name, state, and hint where needed. For Larger Text, test through the largest accessibility size and confirm no primary text overlaps or becomes unusably truncated. Apple requires all common tasks, including purchase flows, to work with a feature before it is declared. Review the [evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria/) before opting in.

## App Store Copy

Use the existing product positioning consistently:

- Subtitle: `Money quests for kids and families`
- Promotional text: `Play quick money missions, try everyday quests, and learn cards, interest, and saving together.`
- Accessibility URL: `https://moneymuncher.ca/kids/accessibility.html`

The product-page screenshots, description, and accessibility answers must match the current build. Update this file whenever an accessibility claim or story experience changes.
