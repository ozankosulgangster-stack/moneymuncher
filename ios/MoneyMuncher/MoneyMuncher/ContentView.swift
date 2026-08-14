import SwiftUI
import UIKit

enum AppDestination: Identifiable, Equatable {
    case play
    case questGenerator
    case scamSmart
    case familyCommunity
    case familySignup
    case account
    case parentGuide
    case support
    case privacy

    var id: String {
        switch self {
        case .play: return "play"
        case .questGenerator: return "quest-generator"
        case .scamSmart: return "scam-smart"
        case .familyCommunity: return "family-community"
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
        case .scamSmart: return "Scam Smart"
        case .familyCommunity: return "Family Community"
        case .familySignup: return "Family Sign Up"
        case .account: return "Account & Data"
        case .parentGuide: return "Parent Guide"
        case .support: return "Help & Support"
        case .privacy: return "Privacy"
        }
    }

    var url: URL? {
        switch self {
        case .play:
            return URL(string: "https://moneymuncher.ca/kids/play/?source=ios-app")!
        case .questGenerator:
            return URL(string: "https://moneymuncher.ca/kids/?source=ios-app#questGeneratorTitle")!
        case .scamSmart:
            return URL(string: "https://moneymuncher.ca/kids/blog/scam-smart.html?source=ios-app")!
        case .familyCommunity:
            return nil
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
        case .familyCommunity, .familySignup, .account, .parentGuide, .support:
            return true
        case .play, .questGenerator, .scamSmart, .privacy:
            return false
        }
    }

}

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var familyStore: FamilyCommunityStore
    @StateObject private var parentAccess = ParentAccessManager.shared

    @State private var activeDestination: AppDestination?
    @State private var gatedDestination: AppDestination?
    @State private var pendingDestinationAfterGate: AppDestination?
    @State private var isShowingParentGate = false
    @State private var isPaywallPending = false
    @State private var isShowingPaywall = false
    @State private var isShowingPremiumLearning = false
    @State private var pendingPremiumLearning = false
    @State private var isShowingFamilyQuest = false
    @State private var isShowingDinoChat = false
    @State private var isShowingChorePlanner = false
    @State private var shouldOpenFamilyQuestAfterWebDismiss = false

    var body: some View {
        NavigationStack {
            ZStack {
                MoneyMuncherScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        LandingAdventureHero(
                            reduceMotion: reduceMotion,
                            onStartQuest: { open(.questGenerator) },
                            onPlay: { open(.play) }
                        )

                        todayCard
                        adventureSection
                        familyToolsSection
                        plusLearning
                        grownUpCorner
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
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
            if destination == .familyCommunity {
                FamilyCommunityView()
            } else {
                WebExperienceView(destination: destination) {
                    shouldOpenFamilyQuestAfterWebDismiss = true
                    activeDestination = nil
                }
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
        .task {
            await purchaseManager.refreshPurchasedProducts()
        }
        .sheet(isPresented: $isShowingPremiumLearning) {
            PremiumLearningHubView()
        }
        .sheet(isPresented: $isShowingPaywall, onDismiss: openPremiumDestinationIfUnlocked) {
            PaywallView(
                onOpenLessons: {
                    pendingPremiumLearning = false
                    isShowingPaywall = false

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        isShowingPremiumLearning = true
                    }
                }
            )
            .environmentObject(purchaseManager)
        }
        .sheet(isPresented: $isShowingParentGate, onDismiss: presentPendingDestination) {
            ParentGateView(
                access: parentAccess,
                onUnlock: {
                    let destination = gatedDestination
                    let shouldShowPaywall = isPaywallPending

                    gatedDestination = nil
                    isPaywallPending = false
                    isShowingParentGate = false

                    if let destination {
                        pendingDestinationAfterGate = destination
                    } else if shouldShowPaywall {
                        Task { @MainActor in
                            let restoredPremiumAccess = await purchaseManager.restorePurchases()

                            if restoredPremiumAccess, pendingPremiumLearning {
                                pendingPremiumLearning = false
                                isShowingPremiumLearning = true
                            } else {
                                isShowingPaywall = true
                            }
                        }
                    }
                },
                onCancel: {
                    gatedDestination = nil
                    pendingPremiumLearning = false
                    isPaywallPending = false
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

    private var closestActiveGoal: FamilyGoal? {
        familyStore.activeGoals.max { $0.progress < $1.progress }
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            landingSectionTitle("Your family today", systemImage: "sun.max.fill")

            Button {
                open(.familyCommunity)
            } label: {
                if let goal = closestActiveGoal {
                    activeGoalSnapshot(goal)
                } else if familyStore.members.isEmpty {
                    emptyFamilySnapshot
                } else {
                    readyForGoalSnapshot
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Parent gate required to open Family Community")
        }
    }

    private func activeGoalSnapshot(_ goal: FamilyGoal) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 13) {
                Text(goal.emoji)
                    .font(.system(size: 32))
                    .frame(width: 52, height: 52)
                    .background(MoneyMuncherDesign.warmGold)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Closest family goal")
                        .font(.caption.weight(.black))
                        .textCase(.uppercase)
                        .tracking(0.7)
                        .foregroundStyle(MoneyMuncherDesign.purple)
                    Text(goal.title)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(MoneyMuncherDesign.ink)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MoneyMuncherDesign.purple)
            }

            GoalSnapshotProgress(progress: goal.progress, reduceMotion: reduceMotion)

            HStack {
                Text("\(FamilyMoneyFormatter.string(cents: goal.savedInCents)) saved")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(MoneyMuncherDesign.ink)
                Spacer()
                Text("\(Int(goal.progress * 100))%")
                    .font(.subheadline.monospacedDigit().weight(.black))
                    .foregroundStyle(MoneyMuncherDesign.green)
            }
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .moneyMuncherCard()
    }

    private var emptyFamilySnapshot: some View {
        HStack(spacing: 14) {
            MoneyMuncherCharacterBadge(
                imageName: "MiraTurtle",
                size: 66,
                tint: MoneyMuncherDesign.familyGreen
            )

            VStack(alignment: .leading, spacing: 5) {
                Text("Build your family crew")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(MoneyMuncherDesign.ink)
                Text("Add a child profile, choose a goal, and make progress visible together.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 2)
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundStyle(MoneyMuncherDesign.purple)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .moneyMuncherCard()
    }

    private var readyForGoalSnapshot: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MoneyMuncherDesign.warmGold)
                    .frame(width: 62, height: 62)
                Image(systemName: "target")
                    .font(.title.weight(.black))
                    .foregroundStyle(Color(red: 0.48, green: 0.31, blue: 0.03))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Your crew is ready")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(MoneyMuncherDesign.ink)
                Text("Create the first family goal and watch the progress bar grow.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 2)
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundStyle(MoneyMuncherDesign.purple)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .moneyMuncherCard()
    }

    private var adventureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            landingSectionTitle("Choose an adventure", systemImage: "map.fill")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    LandingMissionCard(
                        eyebrow: "PLAY",
                        title: "Cup Rush",
                        subtitle: "Collect coins and dodge debt.",
                        systemImage: "soccerball",
                        imageName: "CaptainJackShark",
                        colors: [Color(red: 0.24, green: 0.68, blue: 0.91), Color(red: 0.08, green: 0.48, blue: 0.72)],
                        isLocked: false
                    ) {
                        open(.play)
                    }

                    LandingMissionCard(
                        eyebrow: "CHOOSE",
                        title: "Everyday Quest",
                        subtitle: "Turn a real moment into a money choice.",
                        systemImage: "wand.and.stars",
                        imageName: "DinoTeacher",
                        colors: [Color(red: 0.56, green: 0.42, blue: 1.00), MoneyMuncherDesign.purple],
                        isLocked: false
                    ) {
                        open(.questGenerator)
                    }

                    LandingMissionCard(
                        eyebrow: "GROW",
                        title: "Family Community",
                        subtitle: "Profiles, goals, and shared wins.",
                        systemImage: "house.and.flag.fill",
                        imageName: "MiraTurtle",
                        colors: [Color(red: 0.99, green: 0.56, blue: 0.61), Color(red: 0.91, green: 0.37, blue: 0.51)],
                        isLocked: true
                    ) {
                        open(.familyCommunity)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 1)
            }
        }
    }

    private var plusLearning: some View {
        VStack(alignment: .leading, spacing: 12) {
            landingSectionTitle("Keep growing", systemImage: "sparkles")

            Button {
                openPremiumLearning()
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 120, height: 120)
                        .offset(x: 34, y: 42)

                    HStack(spacing: 15) {
                        DinoAvatar(size: 68)

                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 7) {
                                Text("Dino Money Lab")
                                    .font(.title3.weight(.heavy))
                                Image(systemName: purchaseManager.hasPremiumAccess ? "checkmark.seal.fill" : "crown.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(MoneyMuncherDesign.gold)
                            }
                            Text("Cards, saving, interest, and investing—taught through character adventures.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.82))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(purchaseManager.hasPremiumAccess ? "CONTINUE LEARNING" : "EXPLORE PLUS")
                                .font(.caption.weight(.black))
                                .tracking(0.8)
                                .padding(.top, 4)
                        }
                        .foregroundStyle(.white)

                        Spacer(minLength: 0)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.20, green: 0.13, blue: 0.35), MoneyMuncherDesign.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: MoneyMuncherDesign.purple.opacity(0.20), radius: 14, y: 7)
            }
            .buttonStyle(.plain)
            .accessibilityHint(purchaseManager.hasPremiumAccess ? "Opens Dino Money Lab" : "Parent gate and Plus subscription required")

            if !purchaseManager.hasPremiumAccess {
                Button {
                    requestPaywall()
                } label: {
                    Label("See Money Muncher Plus", systemImage: "crown")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(MoneyMuncherDesign.purple)
                        .background(MoneyMuncherDesign.purpleLight)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Parent gate required before purchase options")
            }
        }
    }

    private var familyToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            landingSectionTitle("Family tools", systemImage: "person.3.fill")

            Button { isShowingFamilyQuest = true } label: {
                nativeToolRow(
                    title: "Family Quest Loop",
                    subtitle: "Create a mission, celebrate the effort, then split virtual coins into Spend, Save, and Share.",
                    systemImage: "flag.checkered",
                    tint: MoneyMuncherDesign.purple
                )
            }

            Button { isShowingChorePlanner = true } label: {
                nativeToolRow(
                    title: "Family Chore Planner",
                    subtitle: "Assign dollars or points and turn completed chores into a simple money plan.",
                    systemImage: "checklist.checked",
                    tint: MoneyMuncherDesign.green
                )
            }

            Button { isShowingDinoChat = true } label: {
                nativeToolRow(
                    title: "Ask Dino",
                    subtitle: "Chat about saving, spending, allowance, needs versus wants, and Market Lab.",
                    systemImage: "bubble.left.and.bubble.right.fill",
                    tint: Color(red: 0.72, green: 0.47, blue: 0.02)
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func nativeToolRow(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            MoneyMuncherIconBadge(systemImage: systemImage, foreground: tint, background: tint.opacity(0.13), size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(MoneyMuncherDesign.ink)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right.circle.fill").font(.title3).foregroundStyle(tint)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .moneyMuncherCard()
    }

    private var grownUpCorner: some View {
        VStack(alignment: .leading, spacing: 12) {
            landingSectionTitle("Grown-up corner", systemImage: "lock.shield.fill")

            VStack(spacing: 0) {
                grownUpLink(
                    title: "Family Community",
                    subtitle: "Manage profiles, shared goals, activities, and reminders.",
                    systemImage: "person.3.fill",
                    destination: .familyCommunity
                )
                Divider().padding(.leading, 60)
                grownUpLink(
                    title: "Account & Data",
                    subtitle: "Sign in, sign out, or permanently delete an account.",
                    systemImage: "person.crop.circle.badge.checkmark",
                    destination: .account
                )
                Divider().padding(.leading, 60)
                grownUpLink(
                    title: "Family Sign Up",
                    subtitle: "Create an account for the web experience.",
                    systemImage: "person.2.badge.plus",
                    destination: .familySignup
                )
                Divider().padding(.leading, 60)
                grownUpLink(
                    title: "Parent Guide",
                    subtitle: "Learning approach, privacy, and play ideas.",
                    systemImage: "checklist.checked",
                    destination: .parentGuide
                )
                Divider().padding(.leading, 60)
                grownUpLink(
                    title: "Help & Support",
                    subtitle: "Get answers or contact Money Muncher support.",
                    systemImage: "questionmark.bubble",
                    destination: .support
                )
            }
            .moneyMuncherCard()
        }
    }

    private func grownUpLink(
        title: String,
        subtitle: String,
        systemImage: String,
        destination: AppDestination
    ) -> some View {
        Button {
            open(destination)
        } label: {
            HStack(spacing: 12) {
                MoneyMuncherIconBadge(
                    systemImage: systemImage,
                    foreground: MoneyMuncherDesign.green,
                    background: Color(red: 0.88, green: 0.96, blue: 0.89),
                    size: 42
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(MoneyMuncherDesign.ink)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Parent gate required")
    }

    private func landingSectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.title3.weight(.heavy))
            .foregroundStyle(MoneyMuncherDesign.ink)
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
        DispatchQueue.main.async { isShowingFamilyQuest = true }
    }

    private func requestPaywall(opensLearningHub: Bool = false) {
        pendingPremiumLearning = opensLearningHub
        gatedDestination = nil
        isPaywallPending = true
        isShowingParentGate = true
    }

    private func openPremiumLearning() {
        if purchaseManager.hasPremiumAccess {
            isShowingPremiumLearning = true
        } else {
            requestPaywall(opensLearningHub: true)
        }
    }

    private func openPremiumDestinationIfUnlocked() {
        guard purchaseManager.hasPremiumAccess else {
            pendingPremiumLearning = false
            return
        }

        if pendingPremiumLearning {
            pendingPremiumLearning = false
            isShowingPremiumLearning = true
        }
    }

}

private struct LandingAdventureHero: View {
    let reduceMotion: Bool
    let onStartQuest: () -> Void
    let onPlay: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 9) {
                Text("A MONEY PLAYGROUND FOR GROWING MINDS")
                    .font(.caption.weight(.black))
                    .tracking(1.1)
                    .foregroundStyle(MoneyMuncherDesign.gold)

                Text("Play. Save.\nGrow.")
                    .font(.system(size: 43, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.82)

                Text("Kick off a game, solve a real-life money choice, or build a family goal—one small win at a time.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 12)

            AnimatedMoneyAdventureScene(reduceMotion: reduceMotion)
                .frame(height: 205)
                .padding(.top, 4)

            VStack(spacing: 10) {
                Button(action: onStartQuest) {
                    Label("Start Today’s Quest", systemImage: "wand.and.stars")
                        .font(.headline.weight(.heavy))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .foregroundStyle(Color(red: 0.15, green: 0.18, blue: 0.12))
                        .background(MoneyMuncherDesign.gold)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onPlay) {
                    Label("Play Cup Rush", systemImage: "soccerball")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.14))
                        .clipShape(Capsule())
                        .overlay { Capsule().stroke(.white.opacity(0.24), lineWidth: 1) }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.18, blue: 0.20), Color(red: 0.04, green: 0.42, blue: 0.34)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: MoneyMuncherDesign.green.opacity(0.24), radius: 18, y: 10)
        .onAppear {
            if reduceMotion {
                hasAppeared = true
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    hasAppeared = true
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct AnimatedMoneyAdventureScene: View {
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let seconds = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let bob = sin(seconds * 2.2)

            ZStack {
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 170, height: 170)
                    .offset(x: 90, y: 12)

                adventureCoin(size: 30)
                    .offset(x: -125, y: -45 + bob * 8)
                    .rotationEffect(.degrees(bob * 7))

                adventureCoin(size: 23)
                    .offset(x: 116, y: -67 - bob * 7)
                    .rotationEffect(.degrees(-bob * 9))

                adventureCoin(size: 18)
                    .offset(x: -65, y: -84 - bob * 5)

                savingsJar(fill: 0.62)
                    .frame(width: 92, height: 118)
                    .offset(x: -102, y: 35 - bob * 2)

                Image("DinoTeacher")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 176, height: 202)
                    .offset(x: 45, y: 12 + bob * 5)
                    .rotationEffect(.degrees(bob * 1.1))
                    .shadow(color: .black.opacity(0.20), radius: 12, y: 7)

                Text("Ready for a money mission?")
                    .font(.caption.weight(.black))
                    .foregroundStyle(MoneyMuncherDesign.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.94))
                    .clipShape(Capsule())
                    .offset(x: -74, y: 82 + bob * 2)
            }
        }
        .accessibilityHidden(true)
    }

    private func adventureCoin(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(MoneyMuncherDesign.gold)
            Circle()
                .stroke(Color(red: 1.00, green: 0.93, blue: 0.57), lineWidth: 3)
            Text("$")
                .font(.system(size: size * 0.45, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.45, green: 0.29, blue: 0.02))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: 4, y: 3)
    }

    private func savingsJar(fill: Double) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.20))

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MoneyMuncherDesign.gold.opacity(0.88), MoneyMuncherDesign.mint],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: proxy.size.height * fill)
                    .padding(6)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.75), lineWidth: 4)

                Capsule()
                    .fill(.white.opacity(0.90))
                    .frame(width: proxy.size.width * 0.78, height: 12)
                    .offset(y: -proxy.size.height + 8)

                Image(systemName: "sparkles")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 20)
            }
        }
    }
}

private struct LandingMissionCard: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String
    let imageName: String
    let colors: [Color]
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(.white.opacity(0.13))
                    .frame(width: 130, height: 130)
                    .offset(x: 38, y: 36)

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 118, height: 130)
                    .offset(x: 16, y: 20)

                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Label(eyebrow, systemImage: systemImage)
                            .font(.caption.weight(.black))
                            .tracking(0.7)
                        Spacer()
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                        }
                    }

                    Text(title)
                        .font(.title2.weight(.heavy))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.80))
                        .frame(width: 146, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                }
                .foregroundStyle(.white)
                .padding(17)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(width: 248, height: 210)
            .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: colors.last?.opacity(0.20) ?? .clear, radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityHint(isLocked ? "Parent gate required" : "Opens this adventure")
    }
}

private struct GoalSnapshotProgress: View {
    let progress: Double
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.14))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [MoneyMuncherDesign.mint, MoneyMuncherDesign.gold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * max(0, min(progress, 1)))
                    .animation(reduceMotion ? nil : .spring(response: 0.65, dampingFraction: 0.78), value: progress)
            }
        }
        .frame(height: 13)
        .accessibilityElement()
        .accessibilityLabel("Family goal progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

private struct WebExperienceView: View {
    @Environment(\.dismiss) private var dismiss
    let destination: AppDestination
    let onOpenFamilyQuest: () -> Void

    var body: some View {
        NavigationStack {
            if let url = destination.url {
                MoneyMuncherWebView(url: url) { event in
                    if event == .openFamilyQuest { openFamilyQuest() }
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
                                Button("Family Quest", action: openFamilyQuest).fontWeight(.semibold)
                            }
                        }
                    }
            }
        }
    }

    private func openFamilyQuest() { onOpenFamilyQuest() }
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
