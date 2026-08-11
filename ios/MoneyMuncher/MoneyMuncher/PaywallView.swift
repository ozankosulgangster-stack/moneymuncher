import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var primaryActionTitle = "Open Dino Lessons"
    let onOpenLessons: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    benefits
                    #if DEBUG && targetEnvironment(simulator)
                    if !purchaseManager.hasPremiumAccess {
                        debugUnlockButton
                    }
                    #endif
                    productOptions
                    restoreButton
                    legalLinks
                }
                .padding(22)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Money Muncher Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await purchaseManager.refreshPurchasedProducts()
                await purchaseManager.loadProducts()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(Color(red: 0.05, green: 0.46, blue: 0.39))

            Text("Unlock Plus")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.05, green: 0.26, blue: 0.23))

            Text("More quests, more levels, and richer family learning loops for kids who want to keep going.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.98, blue: 0.83),
                    Color(red: 0.78, green: 0.93, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            PaywallBenefitRow(systemImage: "map.fill", title: "Level path", subtitle: "Unlock premium mission packs as the Duolingo-style path expands.")
            PaywallBenefitRow(systemImage: "sparkles", title: "Everyday quests", subtitle: "Turn allowance, snacks, birthdays, and saving goals into quick challenges.")
            PaywallBenefitRow(systemImage: "person.3.fill", title: "More family profiles", subtitle: "Grow beyond five child profiles in Family Community.")
            PaywallBenefitRow(systemImage: "book.closed.fill", title: "Dino lessons", subtitle: "Learn cards, interest, and stock-market basics with character-led modules.")
        }
    }

    #if DEBUG && targetEnvironment(simulator)
    private var debugUnlockButton: some View {
        Button {
            purchaseManager.unlockPremiumForDebug()
            onOpenLessons()
            dismiss()
        } label: {
            Label("Unlock Plus in Simulator", systemImage: "hammer.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .accessibilityHint("Unlocks premium content for local simulator testing only")
    }
    #endif

    @ViewBuilder
    private var productOptions: some View {
        if purchaseManager.hasPremiumAccess {
            unlockedState
        } else if purchaseManager.isRefreshingEntitlements || purchaseManager.isLoadingProducts {
            ProgressView("Loading plans...")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
        } else if purchaseManager.products.isEmpty {
            unavailableState
        } else {
            VStack(spacing: 12) {
                ForEach(purchaseManager.products, id: \.id) { product in
                    Button {
                        Task {
                            if await purchaseManager.purchase(product) {
                                onOpenLessons()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(product.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 10)

                            if purchaseManager.activePurchaseProductID == product.id {
                                ProgressView()
                            } else {
                                Text(product.displayPrice)
                                    .font(.headline)
                                    .foregroundStyle(Color(red: 0.04, green: 0.35, blue: 0.30))
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(purchaseManager.activePurchaseProductID != nil)
                }

                if let purchaseMessage = purchaseManager.purchaseMessage {
                    Text(purchaseMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var unlockedState: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color(red: 0.05, green: 0.46, blue: 0.39))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Plus is active")
                        .font(.headline)

                    Text("Premium lessons and quests are unlocked on this device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                onOpenLessons()
                dismiss()
            } label: {
                Label(primaryActionTitle, systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var unavailableState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Plans are not available yet")
                .font(.headline)

            Text("Create the matching subscription products in App Store Connect, then reopen this paywall.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var restoreButton: some View {
        Button {
            Task {
                if await purchaseManager.restorePurchases() {
                    onOpenLessons()
                    dismiss()
                }
            }
        } label: {
            Label("Restore Purchases", systemImage: "arrow.clockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryActionButtonStyle())
        .disabled(purchaseManager.activePurchaseProductID != nil)
    }

    private var legalLinks: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subscriptions renew automatically unless cancelled in App Store account settings.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Link("Privacy Policy", destination: URL(string: "https://moneymuncher.ca/kids/privacy.html")!)
                .font(.footnote.weight(.semibold))
        }
    }
}

private struct PaywallBenefitRow: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .frame(width: 36, height: 36)
                .foregroundStyle(Color(red: 0.05, green: 0.46, blue: 0.39))
                .background(Color(red: 0.88, green: 0.96, blue: 0.89))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
