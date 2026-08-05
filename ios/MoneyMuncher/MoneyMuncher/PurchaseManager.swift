import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    #if DEBUG && targetEnvironment(simulator)
    private static let debugPremiumAccessKey = "MoneyMuncherDebugPremiumAccess"
    #endif

    @Published private(set) var products: [Product] = []
    @Published private(set) var hasPremiumAccess = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isRefreshingEntitlements = false
    @Published private(set) var isUsingSandboxPremiumFallback = false
    @Published private(set) var activePurchaseProductID: String?
    @Published var purchaseMessage: String?

    private var transactionUpdatesTask: Task<Void, Never>?

    init() {
        transactionUpdatesTask = observeTransactionUpdates()

        Task {
            await refreshPurchasedProducts()
            await loadProducts()
        }
    }

    func loadProducts() async {
        guard products.isEmpty else { return }

        isLoadingProducts = true
        purchaseMessage = nil

        do {
            let storeProducts = try await Product.products(for: MoneyMuncherSubscriptionProduct.all)
            products = storeProducts.sorted {
                MoneyMuncherSubscriptionProduct.displayRank(for: $0.id) < MoneyMuncherSubscriptionProduct.displayRank(for: $1.id)
            }
        } catch {
            purchaseMessage = "We could not load subscription options. Please try again."
        }

        isLoadingProducts = false
    }

    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        activePurchaseProductID = product.id
        purchaseMessage = nil

        defer {
            activePurchaseProductID = nil
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                let transaction = try verified(verificationResult)
                await transaction.finish()
                await refreshPurchasedProducts()
                return hasPremiumAccess
            case .userCancelled:
                return false
            case .pending:
                purchaseMessage = "Purchase is pending approval."
                return false
            @unknown default:
                purchaseMessage = "Purchase could not be completed."
                return false
            }
        } catch PurchaseError.failedVerification {
            purchaseMessage = "Purchase verification failed. Please contact support if this continues."
            return false
        } catch {
            purchaseMessage = "Purchase could not be completed. Please try again."
            return false
        }
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        purchaseMessage = nil

        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()

            if !hasPremiumAccess {
                purchaseMessage = "No active Plus subscription was found for this Apple ID."
            } else if isUsingSandboxPremiumFallback {
                purchaseMessage = "Plus was restored from a previous Sandbox test purchase."
            }

            return hasPremiumAccess
        } catch {
            purchaseMessage = "Purchases could not be restored. Please try again."
            return false
        }
    }

    func refreshPurchasedProducts() async {
        isRefreshingEntitlements = true
        defer { isRefreshingEntitlements = false }

        var hasActiveSubscription = false
        var hasSandboxPlusPurchase = false
        let now = Date()

        for await entitlement in Transaction.currentEntitlements {
            guard let transaction = try? verified(entitlement) else {
                continue
            }

            if MoneyMuncherSubscriptionProduct.all.contains(transaction.productID),
               transaction.revocationDate == nil,
               transaction.expirationDate.map({ $0 > now }) ?? true {
                hasActiveSubscription = true
            }
        }

        // TestFlight uses StoreKit's Sandbox environment, where subscriptions expire
        // quickly after a limited number of renewals. Keep beta content testable after
        // a prior Sandbox purchase without changing production entitlement behavior.
        if !hasActiveSubscription {
            for await transactionResult in Transaction.all {
                guard let transaction = try? verified(transactionResult) else {
                    continue
                }

                if MoneyMuncherSubscriptionProduct.all.contains(transaction.productID),
                   transaction.environment == .sandbox {
                    hasSandboxPlusPurchase = true
                    break
                }
            }
        }

        isUsingSandboxPremiumFallback = !hasActiveSubscription && hasSandboxPlusPurchase

        #if DEBUG && targetEnvironment(simulator)
        hasPremiumAccess = hasActiveSubscription || hasSandboxPlusPurchase || UserDefaults.standard.bool(forKey: Self.debugPremiumAccessKey)
        #else
        hasPremiumAccess = hasActiveSubscription || hasSandboxPlusPurchase
        #endif
    }

    #if DEBUG && targetEnvironment(simulator)
    func unlockPremiumForDebug() {
        UserDefaults.standard.set(true, forKey: Self.debugPremiumAccessKey)
        hasPremiumAccess = true
        purchaseMessage = "Plus is unlocked for simulator testing."
    }
    #endif

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }

                if let transaction = try? self.verified(update) {
                    await self.refreshPurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw PurchaseError.failedVerification
        }
    }
}

enum PurchaseError: Error {
    case failedVerification
}
