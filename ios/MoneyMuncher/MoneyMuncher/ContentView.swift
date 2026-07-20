import SwiftUI

enum AppDestination: Identifiable {
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
            return URL(string: "https://moneymuncher.ca/?source=ios-app")!
        case .account:
            return URL(string: "https://moneymuncher.ca/?source=ios-app#account")!
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
    @State private var activeDestination: AppDestination?
    @State private var gatedDestination: AppDestination?
    @State private var isShowingParentGate = false

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
        .sheet(isPresented: $isShowingParentGate) {
            ParentGateView(
                onUnlock: {
                    if let destination = gatedDestination {
                        activeDestination = destination
                    }

                    gatedDestination = nil
                    isShowingParentGate = false
                },
                onCancel: {
                    gatedDestination = nil
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
            gatedDestination = destination
            isShowingParentGate = true
        } else {
            activeDestination = destination
        }
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

                Text("Grown-up areas can include account setup or guidance links. Enter the answer to continue.")
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
