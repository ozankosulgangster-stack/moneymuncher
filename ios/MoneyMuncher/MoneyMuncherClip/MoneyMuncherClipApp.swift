import SwiftUI

@main
struct MoneyMuncherClipApp: App {
    @State private var invocationURL: URL?

    var body: some Scene {
        WindowGroup {
            MoneyMissionClipView(invocationURL: invocationURL)
                .onOpenURL { url in
                    invocationURL = url
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    invocationURL = activity.webpageURL
                }
        }
    }
}
