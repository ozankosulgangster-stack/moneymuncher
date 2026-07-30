import SwiftUI
import UIKit

struct FamilyQuestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = FamilyQuestStore()
    @StateObject private var parentAccess = ParentAccessManager.shared
    @State private var mode: FamilyQuestMode = .kid
    @State private var isShowingParentGate = false
    @State private var isShowingQuestEditor = false
    @State private var rewardQuest: FamilyQuest?

    var body: some View {
        NavigationStack {
            ZStack {
                FamilyQuestPalette.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        balanceStrip
                        modePicker
                        if mode == .kid { kidBoard } else { parentBoard }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Family Quests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $isShowingParentGate) {
            ParentGateView(
                access: parentAccess,
                onUnlock: {
                    isShowingParentGate = false
                    mode = .parent
                },
                onCancel: { isShowingParentGate = false }
            )
        }
        .sheet(isPresented: $isShowingQuestEditor) {
            QuestEditorView(store: store)
        }
        .sheet(item: $rewardQuest) { quest in
            RewardChoiceView(quest: quest, store: store)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            lockParentMode()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if mode == .parent && !parentAccess.refreshSession() {
                lockParentMode()
            }
        }
    }

    private var balanceStrip: some View {
        HStack(spacing: 8) {
            BalancePill(emoji: "👛", value: store.snapshot.spendCoins, label: "Spend", color: FamilyQuestPalette.coral)
            BalancePill(emoji: "🐢", value: store.snapshot.saveCoins, label: "Save", color: FamilyQuestPalette.green)
            BalancePill(emoji: "🐝", value: store.snapshot.shareCoins, label: "Share", color: FamilyQuestPalette.gold)
            BalancePill(emoji: "🔥", value: store.snapshot.streak, label: "Streak", color: FamilyQuestPalette.purple)
        }
        .padding(.top, 8)
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ModeButton(title: "Kid Quest Board", systemImage: "sparkles", isSelected: mode == .kid, color: FamilyQuestPalette.purple) {
                withAnimation(.easeInOut(duration: 0.2)) { lockParentMode() }
            }
            ModeButton(title: "Grown-up Camp", systemImage: "lock.fill", isSelected: mode == .parent, color: FamilyQuestPalette.green) {
                guard mode != .parent else { return }
                openParentMode()
            }
        }
    }

    private var kidBoard: some View {
        VStack(spacing: 18) {
            GuideHero(guide: .rolo, eyebrow: "ROLO'S QUEST BOARD", title: kidHeroTitle, message: kidHeroMessage)

            if store.activeQuests.isEmpty && store.waitingQuests.isEmpty && store.rewardQuests.isEmpty {
                EmptyQuestCard { openParentMode() }
            } else {
                if !store.rewardQuests.isEmpty {
                    QuestSectionTitle(title: "Rewards ready!", subtitle: "Choose what your coins will do next", emoji: "🎉")
                    ForEach(store.rewardQuests) { quest in
                        RewardReadyCard(quest: quest) { rewardQuest = quest }
                    }
                }
                if !store.activeQuests.isEmpty {
                    QuestSectionTitle(title: "Today's missions", subtitle: "Real-world wins waiting for you", emoji: "⚡️")
                    ForEach(store.activeQuests) { quest in
                        KidQuestCard(quest: quest) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) { store.markDone(quest.id) }
                        }
                    }
                }
                if !store.waitingQuests.isEmpty {
                    QuestSectionTitle(title: "At grown-up camp", subtitle: "Waiting for a high-five and approval", emoji: "⛺️")
                    ForEach(store.waitingQuests) { quest in WaitingQuestCard(quest: quest) }
                }
            }
            MoneyCoachCard()
        }
    }

    private var parentBoard: some View {
        VStack(spacing: 18) {
            GuideHero(
                guide: .penny,
                eyebrow: "GROWN-UP CAMP",
                title: store.waitingQuests.isEmpty ? "Plan a tiny real-life win" : "\(store.waitingQuests.count) quest\(store.waitingQuests.count == 1 ? "" : "s") ready to review",
                message: store.waitingQuests.isEmpty
                    ? "Keep quests specific, quick, and encouraging. Five thoughtful minutes beats a giant chore chart."
                    : "Celebrate the effort, check the mission, then release the coins."
            )

            Button { requireParentAccess { isShowingQuestEditor = true } } label: {
                Label("Create a family quest", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(FamilyQuestPrimaryButtonStyle(color: FamilyQuestPalette.green))

            if !store.waitingQuests.isEmpty {
                QuestSectionTitle(title: "Ready for review", subtitle: "Approve the win or send a kind retry", emoji: "🔎")
                ForEach(store.waitingQuests) { quest in
                    ParentReviewCard(
                        quest: quest,
                        onApprove: {
                            requireParentAccess {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { store.approve(quest.id) }
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            }
                        },
                        onRetry: {
                            requireParentAccess {
                                withAnimation(.easeInOut(duration: 0.25)) { store.requestRetry(quest.id) }
                            }
                        }
                    )
                }
            }

            if !store.openQuests.isEmpty {
                QuestSectionTitle(title: "Open quests", subtitle: "What the family is working on", emoji: "📌")
                ForEach(store.openQuests) { quest in
                    ParentQuestRow(quest: quest) { requireParentAccess { store.delete(quest.id) } }
                }
            }

            if !store.completedQuests.isEmpty {
                QuestSectionTitle(title: "Recent victories", subtitle: "Small actions are becoming money habits", emoji: "🏆")
                ForEach(Array(store.completedQuests.prefix(5))) { quest in CompletedQuestRow(quest: quest) }
            }
            ParentPrivacyNote()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { lockParentMode() }
            } label: {
                Label("Lock Grown-up Camp", systemImage: "lock.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(FamilyQuestPalette.green)
        }
    }

    private func openParentMode() {
        if parentAccess.refreshSession() {
            withAnimation(.easeInOut(duration: 0.2)) { mode = .parent }
        } else {
            isShowingParentGate = true
        }
    }

    private func requireParentAccess(_ action: () -> Void) {
        guard parentAccess.refreshSession() else {
            lockParentMode()
            isShowingParentGate = true
            return
        }
        action()
    }

    private func lockParentMode() {
        parentAccess.lock()
        mode = .kid
        isShowingQuestEditor = false
    }

    private var kidHeroTitle: String {
        if !store.rewardQuests.isEmpty { return "Your treasure is ready!" }
        if !store.activeQuests.isEmpty { return "A small quest can make a big difference" }
        if !store.waitingQuests.isEmpty { return "Mission sent to grown-up camp" }
        return "Ready for your first family adventure?"
    }

    private var kidHeroMessage: String {
        if !store.rewardQuests.isEmpty { return "Open your reward and decide how much Future You and Kind You should get." }
        if !store.activeQuests.isEmpty { return "Choose a mission, do the real-world thing, then tap I did it!" }
        if !store.waitingQuests.isEmpty { return "Rolo is guarding your quest while a grown-up checks it." }
        return "Ask a grown-up to create a quick mission. Rolo will keep the quest map safe."
    }
}

private enum FamilyQuestMode { case kid, parent }

struct FamilyQuest: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var details: String
    var rewardCoins: Int
    var dueDate: Date
    var cadence: QuestCadence
    var guideID: String
    var state: FamilyQuestState
    var createdAt: Date
    var completedAt: Date?
    var parentNote: String?
    var spendReward: Int?
    var saveReward: Int?
    var shareReward: Int?
    var guide: QuestGuide { QuestGuide.guide(for: guideID) }
}

enum FamilyQuestState: String, Codable { case active, awaitingApproval, rewardReady, completed }

enum QuestCadence: String, Codable, CaseIterable, Identifiable {
    case once, weekly
    var id: String { rawValue }
    var title: String { self == .once ? "One time" : "Every week" }
}

struct FamilyQuestSnapshot: Codable {
    var quests: [FamilyQuest] = []
    var spendCoins = 0
    var saveCoins = 0
    var shareCoins = 0
    var streak = 0
    var lastApprovalDate: Date?
}

@MainActor
final class FamilyQuestStore: ObservableObject {
    @Published private(set) var snapshot: FamilyQuestSnapshot
    private let storageKey = "moneyMuncher.familyQuest.snapshot.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(FamilyQuestSnapshot.self, from: data) {
            snapshot = decoded
        } else {
            snapshot = FamilyQuestSnapshot()
        }
    }

    var activeQuests: [FamilyQuest] { sortedQuests(in: .active) }
    var waitingQuests: [FamilyQuest] { sortedQuests(in: .awaitingApproval) }
    var rewardQuests: [FamilyQuest] { sortedQuests(in: .rewardReady) }
    var openQuests: [FamilyQuest] {
        snapshot.quests.filter { $0.state != .completed && $0.state != .awaitingApproval }.sorted { $0.dueDate < $1.dueDate }
    }
    var completedQuests: [FamilyQuest] {
        snapshot.quests.filter { $0.state == .completed }.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    func addQuest(title: String, details: String, rewardCoins: Int, dueDate: Date, cadence: QuestCadence, guideID: String) {
        snapshot.quests.append(FamilyQuest(
            id: UUID(), title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            details: details.trimmingCharacters(in: .whitespacesAndNewlines), rewardCoins: rewardCoins,
            dueDate: dueDate, cadence: cadence, guideID: guideID, state: .active, createdAt: Date(),
            completedAt: nil, parentNote: nil, spendReward: nil, saveReward: nil, shareReward: nil
        ))
        persist()
    }

    func markDone(_ id: UUID) {
        guard snapshot.quests.first(where: { $0.id == id })?.state == .active else { return }
        update(id) { $0.state = .awaitingApproval; $0.parentNote = nil }
    }
    func approve(_ id: UUID) {
        guard snapshot.quests.first(where: { $0.id == id })?.state == .awaitingApproval else { return }
        updateStreak()
        update(id) { $0.state = .rewardReady; $0.parentNote = "Approved — great effort!" }
    }
    func requestRetry(_ id: UUID) {
        guard snapshot.quests.first(where: { $0.id == id })?.state == .awaitingApproval else { return }
        update(id) { $0.state = .active; $0.parentNote = "Almost there — give it one more try." }
    }

    func claim(_ id: UUID, plan: RewardPlan) {
        guard let index = snapshot.quests.firstIndex(where: { $0.id == id }), snapshot.quests[index].state == .rewardReady else { return }
        let amounts = plan.amounts(for: snapshot.quests[index].rewardCoins)
        snapshot.spendCoins += amounts.spend
        snapshot.saveCoins += amounts.save
        snapshot.shareCoins += amounts.share
        snapshot.quests[index].spendReward = amounts.spend
        snapshot.quests[index].saveReward = amounts.save
        snapshot.quests[index].shareReward = amounts.share
        snapshot.quests[index].state = .completed
        snapshot.quests[index].completedAt = Date()

        if snapshot.quests[index].cadence == .weekly {
            let old = snapshot.quests[index]
            snapshot.quests.append(FamilyQuest(
                id: UUID(), title: old.title, details: old.details, rewardCoins: old.rewardCoins,
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: old.dueDate) ?? Date(),
                cadence: .weekly, guideID: old.guideID, state: .active, createdAt: Date(), completedAt: nil,
                parentNote: nil, spendReward: nil, saveReward: nil, shareReward: nil
            ))
        }
        persist()
    }

    func delete(_ id: UUID) { snapshot.quests.removeAll { $0.id == id }; persist() }

    private func sortedQuests(in state: FamilyQuestState) -> [FamilyQuest] {
        snapshot.quests.filter { $0.state == state }.sorted { $0.dueDate < $1.dueDate }
    }
    private func update(_ id: UUID, change: (inout FamilyQuest) -> Void) {
        guard let index = snapshot.quests.firstIndex(where: { $0.id == id }) else { return }
        change(&snapshot.quests[index]); persist()
    }
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let previous = snapshot.lastApprovalDate {
            let previousDay = calendar.startOfDay(for: previous)
            if previousDay == today { return }
            snapshot.streak = previousDay == calendar.date(byAdding: .day, value: -1, to: today) ? snapshot.streak + 1 : 1
        } else { snapshot.streak = 1 }
        snapshot.lastApprovalDate = today
    }
    private func persist() {
        if let data = try? JSONEncoder().encode(snapshot) { UserDefaults.standard.set(data, forKey: storageKey) }
    }
}

struct QuestGuide: Identifiable, Equatable {
    let id: String
    let name: String
    let role: String
    let emoji: String
    let colors: [Color]

    static let rolo = QuestGuide(id: "rolo", name: "Rolo Raccoon", role: "Quest Scout", emoji: "🦝", colors: [FamilyQuestPalette.sky, FamilyQuestPalette.purple.opacity(0.75)])
    static let penny = QuestGuide(id: "penny", name: "Penny Panda", role: "Grown-up Guide", emoji: "🐼", colors: [FamilyQuestPalette.mint, FamilyQuestPalette.sky])
    static let tessa = QuestGuide(id: "tessa", name: "Tessa Turtle", role: "Future-You Coach", emoji: "🐢", colors: [FamilyQuestPalette.mint, FamilyQuestPalette.green.opacity(0.8)])
    static let ziggy = QuestGuide(id: "ziggy", name: "Ziggy Fox", role: "Smart-Spend Spotter", emoji: "🦊", colors: [FamilyQuestPalette.peach, FamilyQuestPalette.coral.opacity(0.7)])
    static let beanie = QuestGuide(id: "beanie", name: "Beanie Bee", role: "Kindness Captain", emoji: "🐝", colors: [FamilyQuestPalette.cream, FamilyQuestPalette.gold.opacity(0.85)])
    static let questGuides: [QuestGuide] = [.rolo, .tessa, .ziggy, .beanie]
    static func guide(for id: String) -> QuestGuide { ([rolo, penny, tessa, ziggy, beanie].first { $0.id == id }) ?? rolo }
}

struct RewardPlan: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let emoji: String
    let spendPercent: Int
    let savePercent: Int
    let sharePercent: Int
    static let balanced = RewardPlan(id: "balanced", title: "Balanced Backpack", subtitle: "Enjoy some, grow some, share some", emoji: "🎒", spendPercent: 40, savePercent: 40, sharePercent: 20)
    static let superSaver = RewardPlan(id: "saver", title: "Tessa's Future Fund", subtitle: "Give Future You the biggest piece", emoji: "🐢", spendPercent: 20, savePercent: 70, sharePercent: 10)
    static let kindness = RewardPlan(id: "kindness", title: "Beanie's Kind Split", subtitle: "Make sharing part of the celebration", emoji: "🐝", spendPercent: 30, savePercent: 30, sharePercent: 40)
    static let all: [RewardPlan] = [.balanced, .superSaver, .kindness]
    func amounts(for reward: Int) -> (spend: Int, save: Int, share: Int) {
        let spend = reward * spendPercent / 100
        let save = reward * savePercent / 100
        return (spend, save, reward - spend - save)
    }
}

private struct QuestEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: FamilyQuestStore
    @State private var title = ""
    @State private var details = ""
    @State private var rewardCoins = 20
    @State private var dueDate = Date()
    @State private var cadence: QuestCadence = .once
    @State private var guideID = QuestGuide.rolo.id

    private let presets = [
        QuestPreset(title: "Dinner Helper", details: "Help set or clear the table.", reward: 15, guideID: QuestGuide.rolo.id, emoji: "🍽️"),
        QuestPreset(title: "Tidy Ten", details: "Spend ten focused minutes tidying your space.", reward: 20, guideID: QuestGuide.tessa.id, emoji: "✨"),
        QuestPreset(title: "Kindness Mission", details: "Help someone in the family without being asked twice.", reward: 20, guideID: QuestGuide.beanie.id, emoji: "💛"),
        QuestPreset(title: "Smart Shopper", details: "Compare two prices and explain the better value.", reward: 25, guideID: QuestGuide.ziggy.id, emoji: "🛒")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(presets) { preset in
                                Button {
                                    title = preset.title
                                    details = preset.details
                                    rewardCoins = preset.reward
                                    guideID = preset.guideID
                                } label: {
                                    VStack(spacing: 5) {
                                        Text(preset.emoji).font(.title)
                                        Text(preset.title).font(.caption.weight(.bold)).multilineTextAlignment(.center)
                                    }
                                    .frame(width: 108, height: 78)
                                    .background(FamilyQuestPalette.mint.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: { Text("Quick-start ideas") }
                  footer: { Text("Choose a starter or write a quest that fits your family.") }

                Section("The mission") {
                    TextField("Quest name", text: $title)
                    TextField("What does done look like?", text: $details, axis: .vertical).lineLimit(2...4)
                }
                Section("Reward") {
                    Stepper("\(rewardCoins) Muncher Coins", value: $rewardCoins, in: 5...100, step: 5)
                    DatePicker("Due", selection: $dueDate, displayedComponents: [.date])
                    Picker("Repeats", selection: $cadence) {
                        ForEach(QuestCadence.allCases) { cadence in Text(cadence.title).tag(cadence) }
                    }
                }
                Section("Quest guide") {
                    ForEach(QuestGuide.questGuides) { guide in
                        Button { guideID = guide.id } label: {
                            HStack(spacing: 12) {
                                Text(guide.emoji).font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(guide.name).font(.headline)
                                    Text(guide.role).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if guideID == guide.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(FamilyQuestPalette.green) }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("New Family Quest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        store.addQuest(title: title, details: details, rewardCoins: rewardCoins, dueDate: dueDate, cadence: cadence, guideID: guideID)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct QuestPreset: Identifiable {
    let id = UUID()
    let title: String
    let details: String
    let reward: Int
    let guideID: String
    let emoji: String
}

private struct RewardChoiceView: View {
    @Environment(\.dismiss) private var dismiss
    let quest: FamilyQuest
    @ObservedObject var store: FamilyQuestStore
    @State private var selectedPlan: RewardPlan = .balanced
    @State private var didClaim = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [FamilyQuestPalette.sky, FamilyQuestPalette.cream, FamilyQuestPalette.mint], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView { VStack(spacing: 20) { if didClaim { celebration } else { rewardPicker } }.padding(22) }
        }
    }

    private var rewardPicker: some View {
        VStack(spacing: 18) {
            ZStack {
                ConfettiBurst()
                Text(quest.guide.emoji).font(.system(size: 82)).padding(26).background(.white.opacity(0.88)).clipShape(Circle())
            }
            .frame(height: 180)
            VStack(spacing: 6) {
                Text("QUEST APPROVED!").font(.caption.weight(.black)).tracking(1.4).foregroundStyle(FamilyQuestPalette.green)
                Text("You earned \(quest.rewardCoins) coins").font(.system(size: 32, weight: .black, design: .rounded)).multilineTextAlignment(.center)
                Text("Choose a money move. Every plan uses all of your reward.").font(.body.weight(.medium)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            VStack(spacing: 12) {
                ForEach(RewardPlan.all) { plan in
                    RewardPlanCard(plan: plan, reward: quest.rewardCoins, isSelected: selectedPlan == plan) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selectedPlan = plan }
                    }
                }
            }
            Button {
                store.claim(quest.id, plan: selectedPlan)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { didClaim = true }
            } label: { Label("Feed the three jars", systemImage: "sparkles").frame(maxWidth: .infinity) }
            .buttonStyle(FamilyQuestPrimaryButtonStyle(color: FamilyQuestPalette.purple))
        }
    }

    private var celebration: some View {
        let amounts = selectedPlan.amounts(for: quest.rewardCoins)
        return VStack(spacing: 20) {
            ZStack {
                ConfettiBurst()
                Text("🦖").font(.system(size: 92)).padding(24).background(.white.opacity(0.9)).clipShape(Circle())
            }
            .frame(height: 200)
            Text("Three jars fed!").font(.system(size: 36, weight: .black, design: .rounded))
            Text("Munch says: a smart money plan can include Today You, Future You, and Kind You.")
                .font(.title3.weight(.semibold)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            HStack(spacing: 10) {
                RewardJar(emoji: "🦊", amount: amounts.spend, label: "Spend", color: FamilyQuestPalette.coral)
                RewardJar(emoji: "🐢", amount: amounts.save, label: "Save", color: FamilyQuestPalette.green)
                RewardJar(emoji: "🐝", amount: amounts.share, label: "Share", color: FamilyQuestPalette.gold)
            }
            Button("Back to the quest board") { dismiss() }.frame(maxWidth: .infinity)
                .buttonStyle(FamilyQuestPrimaryButtonStyle(color: FamilyQuestPalette.green))
        }
    }
}

private struct GuideHero: View {
    let guide: QuestGuide
    let eyebrow: String
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(.white.opacity(0.78)).frame(width: 92, height: 92)
                Text(guide.emoji).font(.system(size: 57))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(eyebrow).font(.caption.weight(.black)).tracking(1.1).foregroundStyle(FamilyQuestPalette.ink.opacity(0.72))
                Text(title).font(.title2.weight(.black)).foregroundStyle(FamilyQuestPalette.ink)
                Text(message).font(.subheadline.weight(.semibold)).foregroundStyle(FamilyQuestPalette.ink.opacity(0.72)).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: guide.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(.white.opacity(0.65), lineWidth: 1) }
    }
}

private struct KidQuestCard: View {
    let quest: FamilyQuest
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                GuideIcon(guide: quest.guide, size: 54)
                VStack(alignment: .leading, spacing: 5) {
                    Text(quest.title).font(.title3.weight(.black)).foregroundStyle(FamilyQuestPalette.ink)
                    if !quest.details.isEmpty {
                        Text(quest.details).font(.subheadline.weight(.medium)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 6)
                CoinBadge(coins: quest.rewardCoins)
            }
            HStack {
                Label(quest.dueDate.questDueLabel, systemImage: "calendar")
                Spacer()
                Label(quest.cadence.title, systemImage: quest.cadence == .weekly ? "repeat" : "1.circle")
            }
            .font(.caption.weight(.bold)).foregroundStyle(.secondary)
            if let note = quest.parentNote {
                Label(note, systemImage: "bubble.left.fill")
                    .font(.footnote.weight(.semibold)).foregroundStyle(FamilyQuestPalette.coral).padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading).background(FamilyQuestPalette.peach.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Button(action: onComplete) {
                Label("I did it!", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(FamilyQuestPrimaryButtonStyle(color: FamilyQuestPalette.purple))
        }
        .questSurface()
    }
}

private struct WaitingQuestCard: View {
    let quest: FamilyQuest
    var body: some View {
        HStack(spacing: 13) {
            GuideIcon(guide: quest.guide, size: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text(quest.title).font(.headline)
                Text("Penny Panda is waiting for a grown-up.").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            ProgressView().tint(FamilyQuestPalette.green)
        }
        .questSurface()
    }
}

private struct RewardReadyCard: View {
    let quest: FamilyQuest
    let onOpen: () -> Void
    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(FamilyQuestPalette.gold.opacity(0.25)).frame(width: 68, height: 68)
                    Text("🎁").font(.system(size: 42))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title).font(.headline).foregroundStyle(FamilyQuestPalette.ink)
                    Text("\(quest.rewardCoins) coins are sparkling inside").font(.subheadline.weight(.semibold)).foregroundStyle(FamilyQuestPalette.purple)
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill").font(.title2).foregroundStyle(FamilyQuestPalette.purple)
            }
            .padding(17).frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [FamilyQuestPalette.cream, .white], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(FamilyQuestPalette.gold.opacity(0.55), lineWidth: 2) }
        }
        .buttonStyle(.plain)
    }
}

private struct ParentReviewCard: View {
    let quest: FamilyQuest
    let onApprove: () -> Void
    let onRetry: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                GuideIcon(guide: quest.guide, size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title).font(.headline)
                    Text("Marked complete · \(quest.rewardCoins) coins").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            if !quest.details.isEmpty {
                Text("Done means: \(quest.details)").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                Button(action: onRetry) {
                    Label("Try again", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                }
                .buttonStyle(FamilyQuestSecondaryButtonStyle(color: FamilyQuestPalette.coral))
                Button(action: onApprove) {
                    Label("Approve", systemImage: "hand.thumbsup.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(FamilyQuestPrimaryButtonStyle(color: FamilyQuestPalette.green))
            }
        }
        .questSurface()
    }
}

private struct ParentQuestRow: View {
    let quest: FamilyQuest
    let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            GuideIcon(guide: quest.guide, size: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(quest.title).font(.headline)
                Text(quest.state == .rewardReady ? "Approved · reward waiting" : quest.dueDate.questDueLabel)
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            Spacer()
            CoinBadge(coins: quest.rewardCoins)
            Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }
                .accessibilityLabel("Delete \(quest.title)")
        }
        .questSurface()
    }
}

private struct CompletedQuestRow: View {
    let quest: FamilyQuest
    var body: some View {
        HStack(spacing: 12) {
            Text("🏅").font(.title2)
            VStack(alignment: .leading, spacing: 3) {
                Text(quest.title).font(.headline)
                Text("Spend \(quest.spendReward ?? 0) · Save \(quest.saveReward ?? 0) · Share \(quest.shareReward ?? 0)")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.seal.fill").foregroundStyle(FamilyQuestPalette.green)
        }
        .questSurface()
    }
}

private struct EmptyQuestCard: View {
    let onAskGrownUp: () -> Void
    var body: some View {
        VStack(spacing: 13) {
            HStack(spacing: 8) {
                Text("🦝").font(.system(size: 42)); Text("➕").font(.title); Text("🐼").font(.system(size: 42))
            }
            Text("The quest board is waiting").font(.title3.weight(.black))
            Text("A grown-up can create a one-time mission or a weekly family habit.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Ask a grown-up to add a quest", action: onAskGrownUp)
                .buttonStyle(FamilyQuestPrimaryButtonStyle(color: FamilyQuestPalette.green))
        }
        .padding(22).frame(maxWidth: .infinity).background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct MoneyCoachCard: View {
    var body: some View {
        HStack(spacing: 13) {
            HStack(spacing: -8) { Text("🦊").font(.title); Text("🐢").font(.title); Text("🐝").font(.title) }
            VStack(alignment: .leading, spacing: 4) {
                Text("Meet your money coaches").font(.headline)
                Text("Ziggy cheers for thoughtful spending, Tessa grows Future You's savings, and Beanie helps kindness buzz.")
                    .font(.footnote.weight(.medium)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16).background(FamilyQuestPalette.cream.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ParentPrivacyNote: View {
    var body: some View {
        Label {
            Text("Family Quest data stays on this device in this version. Rewards are virtual practice coins with no cash value.")
        } icon: { Image(systemName: "lock.shield.fill") }
        .font(.footnote.weight(.semibold)).foregroundStyle(.secondary).padding(16)
        .frame(maxWidth: .infinity, alignment: .leading).background(.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct RewardPlanCard: View {
    let plan: RewardPlan
    let reward: Int
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        let amounts = plan.amounts(for: reward)
        return Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text(plan.emoji).font(.title)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.title).font(.headline)
                        Text(plan.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2).foregroundStyle(isSelected ? FamilyQuestPalette.purple : .secondary)
                }
                HStack(spacing: 8) {
                    MiniAllocation(label: "Spend", amount: amounts.spend, color: FamilyQuestPalette.coral)
                    MiniAllocation(label: "Save", amount: amounts.save, color: FamilyQuestPalette.green)
                    MiniAllocation(label: "Share", amount: amounts.share, color: FamilyQuestPalette.gold)
                }
            }
            .padding(15).background(.white.opacity(isSelected ? 0.98 : 0.72))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(isSelected ? FamilyQuestPalette.purple : .white.opacity(0.5), lineWidth: isSelected ? 3 : 1) }
        }
        .buttonStyle(.plain)
    }
}

private struct RewardJar: View {
    let emoji: String
    let amount: Int
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 5) {
            Text(emoji).font(.title)
            Text("+\(amount)").font(.title3.monospacedDigit().weight(.black)).foregroundStyle(color)
            Text(label).font(.caption.weight(.bold)).foregroundStyle(.secondary)
        }
        .padding(.vertical, 15).frame(maxWidth: .infinity).background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct MiniAllocation: View {
    let label: String
    let amount: Int
    let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(amount)").font(.subheadline.monospacedDigit().weight(.black)).foregroundStyle(color)
            Text(label).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
        }
        .padding(.vertical, 7).frame(maxWidth: .infinity).background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ConfettiBurst: View {
    private let colors: [Color] = [FamilyQuestPalette.gold, FamilyQuestPalette.coral, FamilyQuestPalette.green, FamilyQuestPalette.purple]
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                let angle = Double(index) / 20.0 * Double.pi * 2
                let radius = CGFloat(62 + (index % 3) * 18)
                RoundedRectangle(cornerRadius: 2)
                    .fill(colors[index % colors.count]).frame(width: index.isMultiple(of: 2) ? 8 : 5, height: 13)
                    .rotationEffect(.radians(angle)).offset(x: cos(angle) * radius, y: sin(angle) * radius)
            }
        }
    }
}

private struct BalancePill: View {
    let emoji: String
    let value: Int
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 1) {
            Text(emoji).font(.title3)
            Text("\(value)").font(.caption.monospacedDigit().weight(.black)).foregroundStyle(color)
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 9).background(.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore).accessibilityLabel("\(label), \(value) coins")
    }
}

private struct ModeButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage).font(.subheadline.weight(.bold))
                .foregroundStyle(isSelected ? .white : color).padding(.vertical, 11).frame(maxWidth: .infinity)
                .background(isSelected ? color : .white.opacity(0.78)).clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct QuestSectionTitle: View {
    let title: String
    let subtitle: String
    let emoji: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(emoji).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(FamilyQuestPalette.ink)
                Text(subtitle).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GuideIcon: View {
    let guide: QuestGuide
    let size: CGFloat
    var body: some View {
        Text(guide.emoji).font(.system(size: size * 0.58)).frame(width: size, height: size)
            .background(LinearGradient(colors: guide.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(Circle()).accessibilityLabel(guide.name)
    }
}

private struct CoinBadge: View {
    let coins: Int
    var body: some View {
        HStack(spacing: 3) { Text("🪙").font(.caption); Text("\(coins)").font(.caption.monospacedDigit().weight(.black)) }
            .padding(.horizontal, 9).padding(.vertical, 6).background(FamilyQuestPalette.gold.opacity(0.17)).clipShape(Capsule())
            .accessibilityElement(children: .ignore).accessibilityLabel("\(coins) Muncher Coins")
    }
}

private struct FamilyQuestPrimaryButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline.weight(.bold)).padding(.horizontal, 16).padding(.vertical, 13)
            .foregroundStyle(.white).background(configuration.isPressed ? color.opacity(0.72) : color)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous)).scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct FamilyQuestSecondaryButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.bold)).padding(.horizontal, 12).padding(.vertical, 13)
            .foregroundStyle(color).background(configuration.isPressed ? color.opacity(0.18) : color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private struct QuestSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 21, style: .continuous).stroke(.white.opacity(0.65), lineWidth: 1) }
    }
}

private extension View { func questSurface() -> some View { modifier(QuestSurfaceModifier()) } }

private extension Date {
    var questDueLabel: String {
        if Calendar.current.isDateInToday(self) { return "Due today" }
        if Calendar.current.isDateInTomorrow(self) { return "Due tomorrow" }
        return "Due \(formatted(date: .abbreviated, time: .omitted))"
    }
}

private enum FamilyQuestPalette {
    static let ink = Color(red: 0.08, green: 0.20, blue: 0.24)
    static let green = Color(red: 0.04, green: 0.46, blue: 0.37)
    static let purple = Color(red: 0.38, green: 0.29, blue: 0.70)
    static let coral = Color(red: 0.88, green: 0.31, blue: 0.30)
    static let gold = Color(red: 0.88, green: 0.60, blue: 0.07)
    static let sky = Color(red: 0.75, green: 0.91, blue: 0.98)
    static let mint = Color(red: 0.79, green: 0.95, blue: 0.82)
    static let cream = Color(red: 1.00, green: 0.95, blue: 0.76)
    static let peach = Color(red: 1.00, green: 0.82, blue: 0.69)
    static let background = LinearGradient(
        colors: [Color(red: 0.95, green: 0.98, blue: 0.94), Color(red: 0.92, green: 0.95, blue: 1.0)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
