import SwiftUI

@main
struct MoneyMuncherApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
                .task {
                    await purchaseManager.refreshPurchasedProducts()
                }
                .onChange(of: scenePhase) { phase in
                    guard phase == .active else {
                        return
                    }

                    Task {
                        await purchaseManager.refreshPurchasedProducts()
                    }
                }
        }
    }
}
