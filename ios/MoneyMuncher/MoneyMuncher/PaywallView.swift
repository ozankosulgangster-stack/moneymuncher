import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var primaryActionTitle = "Open Dino Lessons"
    let onOpenLessons: () -> Void

    @State private var hasAppeared = false

    private let benefits = [
        PlusBenefit(
            systemImage: "sparkles",
            imageName: "DinoTeacher",
            tint: MoneyMuncherDesign.warmGold,
            title: "Everyday quests",
            subtitle: "Turn allowance, snacks, birthdays, and saving goals into quick challenges."
        ),
        PlusBenefit(
            systemImage: "person.3.fill",
            imageName: "CaptainJackShark",
            tint: MoneyMuncherDesign.purpleLight,
            title: "More family profiles",
            subtitle: "Grow beyond five child profiles in Family Community."
        ),
        PlusBenefit(
            systemImage: "book.closed.fill",
            imageName: "MiraTurtle",
            tint: Color(red: 0.87, green: 0.97, blue: 0.91),
            title: "Character-led lessons",
            subtitle: "Learn cards, interest, saving, and stock-market basics with the Money Muncher crew."
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MoneyMuncherScreenBackground(premium: true)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        hero
                        benefitList

                        #if DEBUG && targetEnvironment(simulator)
                        if !purchaseManager.hasPremiumAccess {
                            debugUnlockButton
                        }
                        #endif

                        productOptions
                        restoreButton
                        legalLinks
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Money Muncher Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .tint(MoneyMuncherDesign.purple)
                }
            }
            .task {
                await purchaseManager.refreshPurchasedProducts()
                await purchaseManager.loadProducts()
            }
            .onAppear {
                guard !hasAppeared else { return }
                if reduceMotion {
                    hasAppeared = true
                } else {
                    withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                        hasAppeared = true
                    }
                }
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 120, height: 120)
                .offset(x: 32, y: 34)

            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 70, height: 70)
                .offset(x: -235, y: -78)

            VStack(alignment: .leading, spacing: 7) {
                Text("PLAY · SAVE · LEARN")
                    .font(.caption.weight(.black))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.80))

                Text(purchaseManager.hasPremiumAccess ? "The whole quest jar is open" : "Unlock the full quest jar")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(
                    purchaseManager.hasPremiumAccess
                        ? "Keep learning with every quest, lesson, and family profile."
                        : "More adventures for curious kids and growing families."
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.84))
                .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: -8) {
                    ForEach(Array(["DinoTeacher", "CaptainJackShark", "MiraTurtle", "OllieOwl", "SammyUnicorn"].enumerated()), id: \.offset) { index, imageName in
                        MoneyMuncherCharacterBadge(
                            imageName: imageName,
                            size: 42,
                            tint: .white.opacity(0.94)
                        )
                        .scaleEffect(hasAppeared ? 1 : 0.55)
                        .offset(y: hasAppeared ? 0 : 12)
                        .animation(
                            reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.68).delay(Double(index) * 0.06),
                            value: hasAppeared
                        )
                    }
                }
                .padding(.top, 8)
                .accessibilityLabel("The Money Muncher learning crew")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 236, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.56, green: 0.42, blue: 1.00), MoneyMuncherDesign.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: MoneyMuncherDesign.purple.opacity(0.25), radius: 16, y: 9)
    }

    private var benefitList: some View {
        VStack(spacing: 12) {
            ForEach(Array(benefits.enumerated()), id: \.element.id) { index, benefit in
                PaywallBenefitRow(benefit: benefit)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 14)
                    .animation(
                        reduceMotion ? nil : .easeOut(duration: 0.35).delay(0.15 + Double(index) * 0.07),
                        value: hasAppeared
                    )
            }
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
            HStack(spacing: 12) {
                ProgressView()
                Text("Loading plans…")
                    .font(.headline)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .moneyMuncherCard()
        } else if purchaseManager.products.isEmpty {
            unavailableState
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose your adventure")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(MoneyMuncherDesign.ink)

                ForEach(purchaseManager.products, id: \.id) { product in
                    purchaseButton(for: product)
                }

                Text("Any introductory offer you are eligible for will appear in Apple’s purchase confirmation.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let purchaseMessage = purchaseManager.purchaseMessage {
                    Label(purchaseMessage, systemImage: "info.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func purchaseButton(for product: Product) -> some View {
        Button {
            Task {
                if await purchaseManager.purchase(product) {
                    onOpenLessons()
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 14) {
                MoneyMuncherIconBadge(
                    systemImage: product.id == MoneyMuncherSubscriptionProduct.annual ? "star.fill" : "calendar",
                    foreground: product.id == MoneyMuncherSubscriptionProduct.annual ? Color(red: 0.67, green: 0.46, blue: 0.02) : MoneyMuncherDesign.purple,
                    background: product.id == MoneyMuncherSubscriptionProduct.annual ? MoneyMuncherDesign.warmGold : MoneyMuncherDesign.purpleLight
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if product.id == MoneyMuncherSubscriptionProduct.annual {
                            Text("BEST VALUE")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(MoneyMuncherDesign.purple)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(MoneyMuncherDesign.purpleLight)
                                .clipShape(Capsule())
                        }
                    }

                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                if purchaseManager.activePurchaseProductID == product.id {
                    ProgressView()
                } else {
                    Text(product.displayPrice)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(MoneyMuncherDesign.purple)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .moneyMuncherCard()
        }
        .buttonStyle(.plain)
        .disabled(purchaseManager.activePurchaseProductID != nil)
        .accessibilityHint("Starts Apple’s purchase confirmation for this plan")
    }

    private var unlockedState: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(MoneyMuncherDesign.mint)
                        .frame(width: 42, height: 42)
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Plus is active")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(MoneyMuncherDesign.ink)
                    Text("Premium quests, profiles, and lessons are unlocked.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                onOpenLessons()
                dismiss()
            } label: {
                Label(primaryActionTitle, systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PurplePillButtonStyle())
        }
        .padding(18)
        .background(Color(red: 0.87, green: 0.97, blue: 0.91))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(MoneyMuncherDesign.mint.opacity(0.45), lineWidth: 1.5)
        }
    }

    private var unavailableState: some View {
        HStack(alignment: .top, spacing: 13) {
            MoneyMuncherIconBadge(systemImage: "wifi.exclamationmark")
            VStack(alignment: .leading, spacing: 5) {
                Text("Plans are not available yet")
                    .font(.headline)
                Text("Check your connection, then close and reopen this screen to try again.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .moneyMuncherCard()
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
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(MoneyMuncherDesign.purple)
        }
        .buttonStyle(.plain)
        .disabled(purchaseManager.activePurchaseProductID != nil)
    }

    private var legalLinks: some View {
        VStack(spacing: 8) {
            Text("Subscriptions renew automatically unless cancelled in App Store account settings.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Link("Privacy Policy", destination: URL(string: "https://moneymuncher.ca/kids/privacy.html")!)
                .font(.footnote.weight(.bold))
                .tint(MoneyMuncherDesign.purple)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PlusBenefit: Identifiable {
    let id = UUID()
    let systemImage: String
    let imageName: String
    let tint: Color
    let title: String
    let subtitle: String
}

private struct PaywallBenefitRow: View {
    let benefit: PlusBenefit

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            MoneyMuncherIconBadge(
                systemImage: benefit.systemImage,
                foreground: MoneyMuncherDesign.purple,
                background: benefit.tint
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(benefit.title)
                    .font(.headline)
                    .foregroundStyle(MoneyMuncherDesign.ink)

                Text(benefit.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            MoneyMuncherCharacterBadge(
                imageName: benefit.imageName,
                size: 38,
                tint: benefit.tint
            )
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .moneyMuncherCard()
    }
}

private struct PurplePillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .padding(.horizontal, 18)
            .frame(minHeight: 52)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [MoneyMuncherDesign.purple.opacity(0.82), MoneyMuncherDesign.purple.opacity(0.72)]
                        : [Color(red: 0.56, green: 0.42, blue: 1.00), MoneyMuncherDesign.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .shadow(color: MoneyMuncherDesign.purple.opacity(0.25), radius: 10, y: 5)
    }
}
