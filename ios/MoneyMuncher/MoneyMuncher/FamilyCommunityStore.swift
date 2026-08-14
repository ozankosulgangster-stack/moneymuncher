import Foundation

struct FamilyMember: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var avatar: String
    let createdAt: Date

    init(id: UUID = UUID(), name: String, avatar: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.createdAt = createdAt
    }
}

struct FamilyActivity: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var note: String
    var participantIDs: [UUID]
    var completedParticipantIDs: Set<UUID>
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        note: String,
        participantIDs: [UUID],
        completedParticipantIDs: Set<UUID> = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.participantIDs = participantIDs
        self.completedParticipantIDs = completedParticipantIDs
        self.createdAt = createdAt
    }

    var isComplete: Bool {
        !participantIDs.isEmpty && participantIDs.allSatisfy(completedParticipantIDs.contains)
    }

    var progress: Double {
        guard !participantIDs.isEmpty else { return 0 }
        let completedCount = participantIDs.filter(completedParticipantIDs.contains).count
        return Double(completedCount) / Double(participantIDs.count)
    }
}

enum FamilyGoalKind: String, Codable, CaseIterable, Identifiable {
    case familySavings
    case giftPool

    var id: String { rawValue }

    var title: String {
        switch self {
        case .familySavings: return "Family Goal"
        case .giftPool: return "Gift Pool"
        }
    }

    var systemImage: String {
        switch self {
        case .familySavings: return "target"
        case .giftPool: return "gift.fill"
        }
    }
}

enum FamilyContributionSource: String, Codable, CaseIterable, Identifiable {
    case manual
    case gift
    case foundMoney
    case roundUp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual: return "Contribution"
        case .gift: return "Gift"
        case .foundMoney: return "Found Money"
        case .roundUp: return "Round-Up"
        }
    }

    var systemImage: String {
        switch self {
        case .manual: return "dollarsign.circle.fill"
        case .gift: return "gift.fill"
        case .foundMoney: return "sparkles"
        case .roundUp: return "arrow.up.circle.fill"
        }
    }
}

enum FamilyGoalReminderKind: String, Codable, CaseIterable, Identifiable {
    case weekly
    case inactivity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: return "Weekly"
        case .inactivity: return "No Progress"
        }
    }
}

struct FamilyGoalReminder: Codable, Equatable {
    var kind: FamilyGoalReminderKind
    var weekday: Int
    var hour: Int
    var minute: Int
    var inactivityDays: Int

    init(
        kind: FamilyGoalReminderKind,
        weekday: Int = 1,
        hour: Int = 18,
        minute: Int = 0,
        inactivityDays: Int = 7
    ) {
        self.kind = kind
        self.weekday = min(max(weekday, 1), 7)
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
        self.inactivityDays = min(max(inactivityDays, 1), 30)
    }

    var summary: String {
        switch kind {
        case .weekly:
            let weekdayName = Calendar.current.weekdaySymbols[weekday - 1]
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            let time = Calendar.current.date(from: components) ?? Date()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return "Every \(weekdayName) at \(formatter.string(from: time))"
        case .inactivity:
            return inactivityDays == 1 ? "After 1 day without progress" : "After \(inactivityDays) days without progress"
        }
    }
}

struct FamilyGoalContribution: Codable, Identifiable, Equatable {
    let id: UUID
    let amountInCents: Int
    let memberID: UUID?
    let contributorName: String
    let note: String
    let source: FamilyContributionSource
    let createdAt: Date

    init(
        id: UUID = UUID(),
        amountInCents: Int,
        memberID: UUID?,
        contributorName: String,
        note: String,
        source: FamilyContributionSource,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amountInCents = amountInCents
        self.memberID = memberID
        self.contributorName = contributorName
        self.note = note
        self.source = source
        self.createdAt = createdAt
    }
}

struct FamilyGoal: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var emoji: String
    var targetInCents: Int
    var participantIDs: [UUID]
    var kind: FamilyGoalKind
    var roundUpTrackingEnabled: Bool
    var reminder: FamilyGoalReminder?
    var contributions: [FamilyGoalContribution]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        emoji: String,
        targetInCents: Int,
        participantIDs: [UUID],
        kind: FamilyGoalKind,
        roundUpTrackingEnabled: Bool = false,
        reminder: FamilyGoalReminder? = nil,
        contributions: [FamilyGoalContribution] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.targetInCents = targetInCents
        self.participantIDs = participantIDs
        self.kind = kind
        self.roundUpTrackingEnabled = roundUpTrackingEnabled
        self.reminder = reminder
        self.contributions = contributions
        self.createdAt = createdAt
    }

    var savedInCents: Int {
        contributions.reduce(0) { $0 + $1.amountInCents }
    }

    var remainingInCents: Int {
        max(targetInCents - savedInCents, 0)
    }

    var progress: Double {
        guard targetInCents > 0 else { return 0 }
        return min(Double(savedInCents) / Double(targetInCents), 1)
    }

    var isComplete: Bool {
        savedInCents >= targetInCents
    }
}

@MainActor
final class FamilyCommunityStore: ObservableObject {
    static let freeMemberLimit = 5

    @Published private(set) var members: [FamilyMember] = []
    @Published private(set) var activities: [FamilyActivity] = []
    @Published private(set) var goals: [FamilyGoal] = []

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let membersKey = "MoneyMuncherFamilyMembers"
    private let activitiesKey = "MoneyMuncherFamilyActivities"
    private let goalsKey = "MoneyMuncherFamilyGoals"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        members = decode([FamilyMember].self, forKey: membersKey) ?? []
        activities = decode([FamilyActivity].self, forKey: activitiesKey) ?? []
        goals = decode([FamilyGoal].self, forKey: goalsKey) ?? []
        removeOrphanedReferences()
    }

    var openActivities: [FamilyActivity] {
        activities.filter { !$0.isComplete }.sorted { $0.createdAt > $1.createdAt }
    }

    var completedActivities: [FamilyActivity] {
        activities.filter(\.isComplete).sorted { $0.createdAt > $1.createdAt }
    }

    var activeGoals: [FamilyGoal] {
        goals.filter { !$0.isComplete }.sorted { $0.createdAt > $1.createdAt }
    }

    var completedGoals: [FamilyGoal] {
        goals.filter(\.isComplete).sorted { $0.createdAt > $1.createdAt }
    }

    func canAddMember(hasPremiumAccess: Bool) -> Bool {
        hasPremiumAccess || members.count < Self.freeMemberLimit
    }

    @discardableResult
    func addMember(name: String, avatar: String, hasPremiumAccess: Bool) -> FamilyMember? {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, canAddMember(hasPremiumAccess: hasPremiumAccess) else { return nil }

        let member = FamilyMember(name: cleanName, avatar: avatar)
        members.append(member)
        persistMembers()
        return member
    }

    func removeMember(id: UUID) {
        members.removeAll { $0.id == id }

        for index in activities.indices.reversed() {
            activities[index].participantIDs.removeAll { $0 == id }
            activities[index].completedParticipantIDs.remove(id)

            if activities[index].participantIDs.isEmpty {
                activities.remove(at: index)
            }
        }

        for index in goals.indices {
            goals[index].participantIDs.removeAll { $0 == id }
        }

        persistMembers()
        persistActivities()
        persistGoals()
    }

    @discardableResult
    func addActivity(title: String, note: String, participantIDs: Set<UUID>) -> FamilyActivity? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let validParticipants = members.map(\.id).filter(participantIDs.contains)
        guard !cleanTitle.isEmpty, !validParticipants.isEmpty else { return nil }

        let activity = FamilyActivity(
            title: cleanTitle,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            participantIDs: validParticipants
        )
        activities.append(activity)
        persistActivities()
        return activity
    }

    func toggleCompletion(activityID: UUID, memberID: UUID) {
        guard let index = activities.firstIndex(where: { $0.id == activityID }),
              activities[index].participantIDs.contains(memberID) else {
            return
        }

        if activities[index].completedParticipantIDs.contains(memberID) {
            activities[index].completedParticipantIDs.remove(memberID)
        } else {
            activities[index].completedParticipantIDs.insert(memberID)
        }

        persistActivities()
    }

    func deleteActivities(at offsets: IndexSet, from source: [FamilyActivity]) {
        let ids = Set(offsets.map { source[$0].id })
        activities.removeAll { ids.contains($0.id) }
        persistActivities()
    }

    @discardableResult
    func addGoal(
        title: String,
        emoji: String,
        targetInCents: Int,
        participantIDs: Set<UUID>,
        kind: FamilyGoalKind
    ) -> FamilyGoal? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let validParticipants = members.map(\.id).filter(participantIDs.contains)
        guard !cleanTitle.isEmpty, targetInCents > 0, !validParticipants.isEmpty else { return nil }

        let goal = FamilyGoal(
            title: cleanTitle,
            emoji: emoji,
            targetInCents: targetInCents,
            participantIDs: validParticipants,
            kind: kind
        )
        goals.append(goal)
        persistGoals()
        return goal
    }

    @discardableResult
    func addContribution(
        goalID: UUID,
        amountInCents: Int,
        memberID: UUID?,
        contributorName: String,
        note: String,
        source: FamilyContributionSource
    ) -> FamilyGoalContribution? {
        guard amountInCents > 0, let index = goals.firstIndex(where: { $0.id == goalID }) else {
            return nil
        }

        let goal = goals[index]
        let selectedMember = memberID
            .flatMap(member(id:))
            .flatMap { goal.participantIDs.contains($0.id) ? $0 : nil }
        let cleanName = contributorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = selectedMember?.name ?? (cleanName.isEmpty ? "Family" : cleanName)
        let contribution = FamilyGoalContribution(
            amountInCents: amountInCents,
            memberID: selectedMember?.id,
            contributorName: displayName,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            source: source
        )
        goals[index].contributions.append(contribution)
        persistGoals()
        return contribution
    }

    @discardableResult
    func addRoundUp(goalID: UUID, purchaseAmountInCents: Int, memberID: UUID?) -> Int? {
        guard purchaseAmountInCents > 0,
              let goal = goal(id: goalID),
              goal.roundUpTrackingEnabled else {
            return nil
        }

        let roundUp = (100 - (purchaseAmountInCents % 100)) % 100
        guard roundUp > 0 else { return nil }
        let contributor = memberID.flatMap(member(id:))?.name ?? "Family"
        let purchase = FamilyMoneyFormatter.string(cents: purchaseAmountInCents)

        guard addContribution(
            goalID: goalID,
            amountInCents: roundUp,
            memberID: memberID,
            contributorName: contributor,
            note: "Rounded up a \(purchase) purchase",
            source: .roundUp
        ) != nil else {
            return nil
        }
        return roundUp
    }

    @discardableResult
    func recordBudgetSurplus(
        goalID: UUID,
        category: String,
        amountInCents: Int,
        memberID: UUID?
    ) -> FamilyGoalContribution? {
        let contributor = memberID.flatMap(member(id:))?.name ?? "Family"
        let cleanCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = cleanCategory.isEmpty ? "Came in under budget" : "Under budget in \(cleanCategory)"
        return addContribution(
            goalID: goalID,
            amountInCents: amountInCents,
            memberID: memberID,
            contributorName: contributor,
            note: message,
            source: .foundMoney
        )
    }

    func setRoundUpTracking(goalID: UUID, isEnabled: Bool) {
        guard let index = goals.firstIndex(where: { $0.id == goalID }) else { return }
        goals[index].roundUpTrackingEnabled = isEnabled
        persistGoals()
    }

    func setGoalReminder(goalID: UUID, reminder: FamilyGoalReminder?) {
        guard let index = goals.firstIndex(where: { $0.id == goalID }) else { return }
        goals[index].reminder = reminder
        persistGoals()
    }

    func deleteGoal(id: UUID) {
        goals.removeAll { $0.id == id }
        persistGoals()
    }

    func member(id: UUID) -> FamilyMember? {
        members.first { $0.id == id }
    }

    func activity(id: UUID) -> FamilyActivity? {
        activities.first { $0.id == id }
    }

    func goal(id: UUID) -> FamilyGoal? {
        goals.first { $0.id == id }
    }

    private func removeOrphanedReferences() {
        let memberIDs = Set(members.map(\.id))
        activities = activities.compactMap { activity in
            var cleaned = activity
            cleaned.participantIDs.removeAll { !memberIDs.contains($0) }
            cleaned.completedParticipantIDs = cleaned.completedParticipantIDs.intersection(memberIDs)
            return cleaned.participantIDs.isEmpty ? nil : cleaned
        }
        for index in goals.indices {
            goals[index].participantIDs.removeAll { !memberIDs.contains($0) }
        }
        persistActivities()
        persistGoals()
    }

    private func decode<Value: Decodable>(_ type: Value.Type, forKey key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private func persistMembers() {
        guard let data = try? encoder.encode(members) else { return }
        defaults.set(data, forKey: membersKey)
    }

    private func persistActivities() {
        guard let data = try? encoder.encode(activities) else { return }
        defaults.set(data, forKey: activitiesKey)
    }

    private func persistGoals() {
        guard let data = try? encoder.encode(goals) else { return }
        defaults.set(data, forKey: goalsKey)
    }
}

enum FamilyMoneyFormatter {
    static func string(cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "CAD"
        formatter.maximumFractionDigits = cents % 100 == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$0"
    }

    static func cents(from text: String) -> Int? {
        let normalized = text
            .replacingOccurrences(of: Locale.current.groupingSeparator ?? ",", with: "")
            .replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Decimal(string: normalized), value > 0 else { return nil }
        let cents = value * 100
        return NSDecimalNumber(decimal: cents).intValue
    }
}
