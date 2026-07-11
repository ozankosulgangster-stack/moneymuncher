import SwiftUI

enum AppDestination: Identifiable {
    case play
    case questGenerator
    case familySignup
    case parentGuide
    case privacy

    var id: String {
        switch self {
        case .play: return "play"
        case .questGenerator: return "quest-generator"
        case .familySignup: return "family-signup"
        case .parentGuide: return "parent-guide"
        case .privacy: return "privacy"
        }
    }

    var title: String {
        switch self {
        case .play: return "Cup Rush"
        case .questGenerator: return "Everyday Quest"
        case .familySignup: return "Family Sign Up"
        case .parentGuide: return "Parent Guide"
        case .privacy: return "Privacy"
        }
    }

    var url: URL {
        switch self {
        case .play:
            return URL(string: "https://moneymuncher.ca/kids/play/?source=ios-app")!
        case .questGenerator:
            return URL(string: "https://moneymuncher.ca/kids/?source=ios-app#questGeneratorTitle")!
        case .familySignup:
            return URL(string: "https://moneymuncher.ca/?source=ios-app")!
        case .parentGuide:
            return URL(string: "https://moneymuncher.ca/kids/parent-guide.html?source=ios-app")!
        case .privacy:
            return URL(string: "https://moneymuncher.ca/kids/privacy.html?source=ios-app")!
        }
    }

    var requiresParentGate: Bool {
        switch self {
        case .familySignup, .parentGuide:
            return true
        case .play, .questGenerator, .privacy:
            return false
        }
    }

    var requiresPremium: Bool {
        switch self {
        case .questGenerator:
            return true
        case .play, .familySignup, .parentGuide, .privacy:
            return false
        }
    }
}

private struct FeatureCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let destination: AppDestination
    let requiresPremium: Bool

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        destination: AppDestination,
        requiresPremium: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.destination = destination
        self.requiresPremium = requiresPremium
    }
}

struct ContentView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var activeDestination: AppDestination?
    @State private var gatedDestination: AppDestination?
    @State private var premiumDestination: AppDestination?
    @State private var isShowingParentGate = false
    @State private var isPaywallPending = false
    @State private var isShowingPaywall = false

    private let kidCards = [
        FeatureCard(
            title: "Play Cup Rush",
            subtitle: "Collect coins, dodge debt, and race through the Money Muncher stadium.",
            systemImage: "soccerball",
            destination: .play
        ),
        FeatureCard(
            title: "Everyday Quest",
            subtitle: "Plus unlocks snack runs, birthdays, and allowance moments as quick money choices.",
            systemImage: "sparkles",
            destination: .questGenerator,
            requiresPremium: true
        )
    ]

    private let familyCards = [
        FeatureCard(
            title: "Family Sign Up",
            subtitle: "Create an account and keep learning progress together.",
            systemImage: "person.2.badge.plus",
            destination: .familySignup
        ),
        FeatureCard(
            title: "Parent Guide",
            subtitle: "Review the learning approach, privacy notes, and family play ideas.",
            systemImage: "checklist.checked",
            destination: .parentGuide
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    premiumStatus
                    section(title: "Kid Missions", cards: kidCards)
                    section(title: "Family Area", cards: familyCards)
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Money Muncher")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        open(.privacy)
                    } label: {
                        Image(systemName: "lock.shield")
                    }
                    .accessibilityLabel("Open privacy")
                }
            }
        }
        .sheet(item: $activeDestination) { destination in
            WebExperienceView(destination: destination)
        }
        .sheet(isPresented: $isShowingPaywall, onDismiss: openPremiumDestinationIfUnlocked) {
            PaywallView {
                isShowingPaywall = false
            }
            .environmentObject(purchaseManager)
        }
        .sheet(isPresented: $isShowingParentGate) {
            ParentGateView(
                onUnlock: {
                    let destination = gatedDestination
                    let shouldShowPaywall = isPaywallPending

                    gatedDestination = nil
                    isPaywallPending = false
                    isShowingParentGate = false

                    if let destination {
                        DispatchQueue.main.async {
                            activeDestination = destination
                        }
                    } else if shouldShowPaywall {
                        DispatchQueue.main.async {
                            isShowingPaywall = true
                        }
                    }
                },
                onCancel: {
                    gatedDestination = nil
                    premiumDestination = nil
                    isPaywallPending = false
                    isShowingParentGate = false
                }
            )
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Money Muncher")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.05, green: 0.26, blue: 0.23))

            Text("Tiny money missions for curious kids and practical family conversations.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button {
                    open(.play)
                } label: {
                    Label("Kick Off", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryActionButtonStyle())

                Button {
                    open(.questGenerator)
                } label: {
                    Label("Quest", systemImage: "wand.and.stars")
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.91, green: 0.98, blue: 0.82),
                    Color(red: 0.75, green: 0.91, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var premiumStatus: some View {
        Button {
            requestPaywall()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: purchaseManager.hasPremiumAccess ? "checkmark.seal.fill" : "crown.fill")
                    .font(.title2.weight(.bold))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color(red: 0.05, green: 0.46, blue: 0.39))
                    .background(Color(red: 0.88, green: 0.96, blue: 0.89))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(purchaseManager.hasPremiumAccess ? "Plus Active" : "Money Muncher Plus")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(purchaseManager.hasPremiumAccess ? "Premium quests are unlocked." : "Unlock level paths, quest packs, and richer family progress.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                Image(systemName: purchaseManager.hasPremiumAccess ? "checkmark" : "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint(purchaseManager.hasPremiumAccess ? "Premium access is active" : "Parent gate required before purchase options")
    }

    private func section(title: String, cards: [FeatureCard]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color(red: 0.05, green: 0.26, blue: 0.23))

            ForEach(cards) { card in
                Button {
                    open(card.destination)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: card.systemImage)
                            .font(.title2.weight(.bold))
                            .frame(width: 44, height: 44)
                            .foregroundStyle(Color(red: 0.05, green: 0.46, blue: 0.39))
                            .background(Color(red: 0.88, green: 0.96, blue: 0.89))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.title)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(card.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 10)

                        Image(systemName: trailingIcon(for: card))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHint(accessibilityHint(for: card))
            }
        }
    }

    private func open(_ destination: AppDestination) {
        if destination.requiresPremium && !purchaseManager.hasPremiumAccess {
            requestPaywall(for: destination)
            return
        }

        if destination.requiresParentGate {
            gatedDestination = destination
            isShowingParentGate = true
        } else {
            activeDestination = destination
        }
    }

    private func requestPaywall(for destination: AppDestination? = nil) {
        premiumDestination = destination
        gatedDestination = nil
        isPaywallPending = true
        isShowingParentGate = true
    }

    private func openPremiumDestinationIfUnlocked() {
        guard purchaseManager.hasPremiumAccess, let destination = premiumDestination else {
            premiumDestination = nil
            return
        }

        premiumDestination = nil
        activeDestination = destination
    }

    private func trailingIcon(for card: FeatureCard) -> String {
        if card.destination.requiresParentGate {
            return "lock.fill"
        }

        if card.requiresPremium && !purchaseManager.hasPremiumAccess {
            return "crown.fill"
        }

        return "chevron.right"
    }

    private func accessibilityHint(for card: FeatureCard) -> String {
        if card.destination.requiresParentGate {
            return "Parent gate required"
        }

        if card.requiresPremium && !purchaseManager.hasPremiumAccess {
            return "Plus subscription required"
        }

        return "Opens Money Muncher"
    }
}

private struct WebExperienceView: View {
    @Environment(\.dismiss) private var dismiss
    let destination: AppDestination

    var body: some View {
        NavigationStack {
            MoneyMuncherWebView(url: destination.url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(destination.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

private struct ParentGateView: View {
    let onUnlock: () -> Void
    let onCancel: () -> Void

    @State private var answer = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Color(red: 0.05, green: 0.46, blue: 0.39))

                Text("Parent Check")
                    .font(.largeTitle.bold())

                Text("Grown-up areas can include account setup, purchases, or guidance links. Enter the answer to continue.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What is 9 + 4?")
                        .font(.headline)

                    TextField("Answer", text: $answer)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }

                Button {
                    if answer.trimmingCharacters(in: .whitespacesAndNewlines) == "13" {
                        onUnlock()
                    } else {
                        errorMessage = "Try again or ask a grown-up."
                    }
                } label: {
                    Text("Unlock")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())

                Spacer()
            }
            .padding(24)
            .navigationTitle("Parent Gate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .foregroundStyle(.white)
            .background(configuration.isPressed ? Color(red: 0.02, green: 0.30, blue: 0.25) : Color(red: 0.04, green: 0.43, blue: 0.36))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .foregroundStyle(Color(red: 0.04, green: 0.35, blue: 0.30))
            .background(configuration.isPressed ? Color(red: 0.82, green: 0.93, blue: 0.88) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
