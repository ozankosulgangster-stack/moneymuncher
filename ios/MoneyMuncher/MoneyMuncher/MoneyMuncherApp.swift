import SwiftUI

@main
struct MoneyMuncherApp: App {
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
        }
    }
}
