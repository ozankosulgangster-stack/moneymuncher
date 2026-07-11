import Foundation

enum MoneyMuncherSubscriptionProduct {
    static let monthly = "ca.moneymuncher.app.plus.monthly"
    static let annual = "ca.moneymuncher.app.plus.annual"

    static let all = [
        annual,
        monthly
    ]

    static func displayRank(for productID: String) -> Int {
        all.firstIndex(of: productID) ?? all.count
    }
}
