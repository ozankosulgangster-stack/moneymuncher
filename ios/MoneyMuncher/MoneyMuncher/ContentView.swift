import SwiftUI
import UIKit

enum AppDestination: Identifiable, Equatable {
    case play
    case questGenerator
    case familySignup
    case account
    case parentGuide
    case support
    case privacy

    var id: String {
        switch self {
        case .play: return "play"
        case .questGenerator: return "quest-generator"
        case .familySignup: return "family-signup"
        case .account: return "account"
        case .parentGuide: return "parent-guide"
        case .support: return "support"
        case .privacy: return "privacy"
        }
    }

    var title: String {
        switch self {
        case .play: return "Cup Rush"
        case .questGenerator: return "Everyday Quest"
        case .familySignup: return "Family Sign Up"
        case .account: return "Account & Data"
        case .parentGuide: return "Parent Guide"
        case .support: return "Help & Support"
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
            return URL(string: "https://moneymuncher.ca/?source=ios-app&action=signup&reviewBuild=9")!
        case .account:
            return URL(string: "https://moneymuncher.ca/?source=ios-app&action=signin&reviewBuild=9#account")!
        case .parentGuide:
            return URL(string: "https://moneymuncher.ca/kids/parent-guide.html?source=ios-app")!
        case .support:
            return URL(string: "https://moneymuncher.ca/support.html?source=ios-app")!
        case .privacy:
            return URL(string: "https://moneymuncher.ca/kids/privacy.html?source=ios-app")!
        }
    }

    var requiresParentGate: Bool {
        switch self {
        case .familySignup, .account, .parentGuide, .support:
            return true
        case .play, .questGenerator, .privacy:
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
}

struct ContentView: View {
    @StateObject private var parentAccess = ParentAccessManager.shared
    @State private var activeDestination: AppDestination?
    @State private var gatedDestination: AppDestination?
    @State private var pendingDestinationAfterGate: AppDestination?
    @State private var isShowingParentGate = false
    @State private var isShowingFamilyQuest = false
    @State private var isShowingDinoChat = false
    @State private var isShowingChorePlanner = false
    @State private var shouldOpenFamilyQuestAfterWebDismiss = false

    private let kidCards = [
        FeatureCard(
            title: "Play Cup Rush",
            subtitle: "Collect coins, dodge debt, and race through the Money Muncher stadium.",
            systemImage: "soccerball",
            destination: .play
        ),
        FeatureCard(
            title: "Everyday Quest",
            subtitle: "Turn snack runs, birthdays, and allowance moments into quick money choices.",
            systemImage: "sparkles",
            destination: .questGenerator
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
            title: "Account & Data",
            subtitle: "Sign in, sign out, or permanently delete an account and its cloud-saved data.",
            systemImage: "person.crop.circle.badge.checkmark",
            destination: .account
        ),
        FeatureCard(
            title: "Parent Guide",
            subtitle: "Review the learning approach, privacy notes, and family play ideas.",
            systemImage: "checklist.checked",
            destination: .parentGuide
        ),
        FeatureCard(
            title: "Help & Support",
            subtitle: "Get answers or contact Money Muncher support.",
            systemImage: "questionmark.bubble",
            destination: .support
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    familyQuestSpotlight
                    chorePlannerSpotlight
                    dinoChatSpotlight
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
        .fullScreenCover(item: $activeDestination, onDismiss: presentFamilyQuestAfterWebDismiss) { destination in
            WebExperienceView(destination: destination) {
                shouldOpenFamilyQuestAfterWebDismiss = true
                activeDestination = nil
            }
        }
        .fullScreenCover(isPresented: $isShowingFamilyQuest) {
            FamilyQuestView()
        }
        .fullScreenCover(isPresented: $isShowingDinoChat) {
            DinoChatView()
        }
        .fullScreenCover(isPresented: $isShowingChorePlanner) {
            ChorePlannerView()
        }
        .sheet(isPresented: $isShowingParentGate, onDismiss: presentPendingDestination) {
            ParentGateView(
                access: parentAccess,
                onUnlock: {
                    pendingDestinationAfterGate = gatedDestination
                    gatedDestination = nil
                    isShowingParentGate = false
                },
                onCancel: {
                    pendingDestinationAfterGate = nil
                    gatedDestination = nil
                    isShowingParentGate = false
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            parentAccess.lock()
            if activeDestination?.requiresParentGate == true {
                activeDestination = nil
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if activeDestination?.requiresParentGate == true && !parentAccess.refreshSession() {
                activeDestination = nil
            }
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
                    isShowingFamilyQuest = true
                } label: {
                    Label("Family Quest", systemImage: "flag.checkered")
                }
                .buttonStyle(PrimaryActionButtonStyle())

                Button {
                    open(.play)
                } label: {
                    Label("Cup Rush", systemImage: "soccerball")
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

    private var familyQuestSpotlight: some View {
        Button {
            isShowingFamilyQuest = true
        } label: {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.82))
                        .frame(width: 74, height: 74)

                    HStack(spacing: -8) {
                        Text("🦝")
                        Text("🐼")
                    }
                    .font(.system(size: 35))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("NEW · FAMILY QUEST LOOP")
                        .font(.caption.weight(.black))
                        .tracking(1)
                        .foregroundStyle(Color(red: 0.32, green: 0.22, blue: 0.64))

                    Text("Turn real-world wins into money choices")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color(red: 0.08, green: 0.20, blue: 0.24))
                        .multilineTextAlignment(.leading)

                    Text("Create a mission, celebrate the effort, then split virtual coins into Spend, Save, and Share.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.38, green: 0.29, blue: 0.70))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.94, blue: 0.72),
                        Color(red: 0.82, green: 0.92, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the native Family Quest experience")
    }

    private var dinoChatSpotlight: some View {
        Button {
            isShowingDinoChat = true
        } label: {
            HStack(spacing: 15) {
                Text("🦕")
                    .font(.system(size: 46))
                    .frame(width: 72, height: 72)
                    .background(Color.white.opacity(0.84))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("LIVE · AZURE FOUNDRY AGENT")
                        .font(.caption.weight(.black))
                        .tracking(1)
                        .foregroundStyle(Color(red: 0.06, green: 0.42, blue: 0.36))

                    Text("Ask Dino a money question")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color(red: 0.08, green: 0.20, blue: 0.24))
                        .multilineTextAlignment(.leading)

                    Text("Chat freely about saving, spending, allowance, needs versus wants, and Market Lab.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.04, green: 0.43, blue: 0.36))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.82, green: 0.96, blue: 0.89),
                        Color(red: 0.78, green: 0.92, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens a live chat with the Dino Munch family money agent")
    }

    private var chorePlannerSpotlight: some View {
        Button {
            isShowingChorePlanner = true
        } label: {
            HStack(spacing: 15) {
                Image(systemName: "checklist.checked")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color(red: 0.04, green: 0.43, blue: 0.36))
                    .frame(width: 72, height: 72)
                    .background(Color.white.opacity(0.84))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("NEW · NATIVE FAMILY TOOL")
                        .font(.caption.weight(.black))
                        .tracking(1)
                        .foregroundStyle(Color(red: 0.45, green: 0.25, blue: 0.02))

                    Text("Turn chores into a money plan")
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color(red: 0.08, green: 0.20, blue: 0.24))
                        .multilineTextAlignment(.leading)

                    Text("Assign dollars or points, split rewards into Spend, Save, and Give, then share the plan as a CSV.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.82, green: 0.48, blue: 0.08))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.93, blue: 0.68),
                        Color(red: 0.82, green: 0.96, blue: 0.89)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the native family chore planner")
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

                        Image(systemName: card.destination.requiresParentGate ? "lock.fill" : "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHint(card.destination.requiresParentGate ? "Parent gate required" : "Opens Money Muncher")
            }
        }
    }

    private func open(_ destination: AppDestination) {
        if destination.requiresParentGate {
            if parentAccess.refreshSession() {
                activeDestination = destination
                return
            }
            gatedDestination = destination
            isShowingParentGate = true
        } else {
            activeDestination = destination
        }
    }

    private func presentPendingDestination() {
        guard let destination = pendingDestinationAfterGate else { return }
        pendingDestinationAfterGate = nil
        activeDestination = destination
    }

    private func presentFamilyQuestAfterWebDismiss() {
        guard shouldOpenFamilyQuestAfterWebDismiss else { return }
        shouldOpenFamilyQuestAfterWebDismiss = false

        // On iPad, presenting another full-screen cover during the web cover's
        // dismissal transaction can be ignored. Start a fresh transaction only
        // after SwiftUI confirms the web experience has fully dismissed.
        DispatchQueue.main.async {
            isShowingFamilyQuest = true
        }
    }
}

private struct WebExperienceView: View {
    @Environment(\.dismiss) private var dismiss
    let destination: AppDestination
    let onOpenFamilyQuest: () -> Void

    var body: some View {
        NavigationStack {
            MoneyMuncherWebView(url: destination.url) { event in
                if event == .openFamilyQuest {
                    openFamilyQuest()
                }
            }
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(destination.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }

                    if destination == .familySignup || destination == .account {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Family Quest") {
                                openFamilyQuest()
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }
        }
    }

    private func openFamilyQuest() {
        onOpenFamilyQuest()
    }
}

private struct PrimaryActionButtonStyle: ButtonStyle {
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

private struct SecondaryActionButtonStyle: ButtonStyle {
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
