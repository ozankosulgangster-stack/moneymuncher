import SwiftUI

@main
struct MoneyMuncherApp: App {
    @UIApplicationDelegateAdaptor(MoneyMuncherNotificationDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var familyStore = FamilyCommunityStore()
    @StateObject private var notificationManager = FamilyNotificationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
                .environmentObject(familyStore)
                .environmentObject(notificationManager)
                .task {
                    await purchaseManager.refreshPurchasedProducts()
                    await notificationManager.reconcile(goals: familyStore.goals)
                }
                .onChange(of: familyStore.goals) { goals in
                    Task {
                        await notificationManager.reconcile(goals: goals)
                    }
                }
                .onChange(of: scenePhase) { phase in
                    guard phase == .active else {
                        return
                    }

                    Task {
                        await purchaseManager.refreshPurchasedProducts()
                        await notificationManager.reconcile(goals: familyStore.goals)
                    }
                }
        }
    }
}
