import SwiftUI

@main
struct MoneyMuncherApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var familyStore = FamilyCommunityStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
                .environmentObject(familyStore)
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
