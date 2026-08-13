import SwiftUI
import UIKit

struct FamilyGoalsSection: View {
    @EnvironmentObject private var familyStore: FamilyCommunityStore
    @State private var isShowingNewGoal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Family Goals")
                        .font(.subheadline.weight(.black))
                        .textCase(.uppercase)
                        .tracking(0.7)
                        .foregroundStyle(MoneyMuncherDesign.purple)
                    Text("\(familyStore.activeGoals.count) active · \(familyStore.completedGoals.count) reached")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                MoneyMuncherActionChip(
                    title: "Create",
                    systemImage: "plus",
                    isEnabled: !familyStore.members.isEmpty
                ) {
                    isShowingNewGoal = true
                }
            }

            if familyStore.members.isEmpty {
                FamilyGoalEmptyCard(
                    systemImage: "target",
                    title: "Profiles come first",
                    message: "Add at least one child profile before creating a family goal.",
                    imageName: "DinoTeacher"
                )
            } else if familyStore.goals.isEmpty {
                FamilyGoalEmptyCard(
                    systemImage: "chart.bar.fill",
                    title: "Make progress visible",
                    message: "Create a cottage fund, bike fund, or any goal the family can reach together.",
                    imageName: "MiraTurtle"
                )
            } else {
                if !familyStore.activeGoals.isEmpty {
                    goalGroup(title: "Saving Now", goals: familyStore.activeGoals)
                }

                if !familyStore.completedGoals.isEmpty {
                    goalGroup(title: "Goals Reached", goals: familyStore.completedGoals)
                }
            }
        }
        .sheet(isPresented: $isShowingNewGoal) {
            NewFamilyGoalView()
                .environmentObject(familyStore)
        }
    }

    private func goalGroup(title: String, goals: [FamilyGoal]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)

            ForEach(goals) { goal in
                NavigationLink {
                    FamilyGoalDetailView(goalID: goal.id)
                        .environmentObject(familyStore)
                } label: {
                    FamilyGoalRow(goal: goal)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct FamilyGoalRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let goal: FamilyGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(goal.emoji)
                    .font(.system(size: 30))
                    .frame(width: 48, height: 48)
                    .background(Color(red: 1.0, green: 0.95, blue: 0.80))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundStyle(MoneyMuncherDesign.ink)
                    Label(goal.kind.title, systemImage: goal.kind.systemImage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: goal.isComplete ? "checkmark.seal.fill" : "chevron.right")
                    .foregroundStyle(goal.isComplete ? Color.green : Color.secondary)
            }

            GoalProgressBar(progress: goal.progress)

            HStack {
                Text("\(FamilyMoneyFormatter.string(cents: goal.savedInCents)) saved")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("of \(FamilyMoneyFormatter.string(cents: goal.targetInCents))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .moneyMuncherCard()
        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.78), value: goal.progress)
    }
}

private struct GoalProgressBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.16))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.14, green: 0.69, blue: 0.50), Color(red: 0.98, green: 0.73, blue: 0.22)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * max(0, min(progress, 1)))
                    .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 14)
        .accessibilityElement()
        .accessibilityLabel("Goal progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

private struct FamilyGoalEmptyCard: View {
    let systemImage: String
    let title: String
    let message: String
    let imageName: String

    var body: some View {
        HStack(spacing: 14) {
            MoneyMuncherIconBadge(
                systemImage: systemImage,
                foreground: MoneyMuncherDesign.green,
                background: Color(red: 0.88, green: 0.96, blue: 0.89)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(MoneyMuncherDesign.ink)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 2)

            MoneyMuncherCharacterBadge(
                imageName: imageName,
                size: 38,
                tint: MoneyMuncherDesign.familyGreen
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .moneyMuncherCard()
    }
}

private struct NewFamilyGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyStore: FamilyCommunityStore

    @State private var title = ""
    @State private var targetAmount = ""
    @State private var emoji = "🏡"
    @State private var kind: FamilyGoalKind = .familySavings
    @State private var selectedParticipantIDs: Set<UUID> = []

    private let emojis = ["🏡", "🚲", "🎓", "🎁", "🏕️", "✈️", "🐶", "🎮"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("What are you saving for?", text: $title)
                    TextField("Target amount", text: $targetAmount)
                        .keyboardType(.decimalPad)

                    Picker("Goal type", selection: $kind) {
                        ForEach(FamilyGoalKind.allCases) { option in
                            Label(option.title, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                }

                Section("Choose an icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(emojis, id: \.self) { option in
                            Button {
                                emoji = option
                            } label: {
                                Text(option)
                                    .font(.system(size: 28))
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(emoji == option ? Color.green.opacity(0.18) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(emoji == option ? .isSelected : [])
                        }
                    }
                }

                Section("Participants") {
                    ForEach(familyStore.members) { member in
                        Button {
                            toggle(member.id)
                        } label: {
                            HStack {
                                Text(member.avatar)
                                Text(member.name).foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: selectedParticipantIDs.contains(member.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedParticipantIDs.contains(member.id) ? Color.green : Color.secondary)
                            }
                        }
                    }
                }

                if kind == .giftPool {
                    Section {
                        Label("You can share an invitation after creating the pool. Contributions are recorded manually; this version does not collect or transfer payments.", systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Family Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard let cents = FamilyMoneyFormatter.cents(from: targetAmount) else { return }
                        if familyStore.addGoal(
                            title: title,
                            emoji: emoji,
                            targetInCents: cents,
                            participantIDs: selectedParticipantIDs,
                            kind: kind
                        ) != nil {
                            dismiss()
                        }
                    }
                    .disabled(!canCreate)
                }
            }
            .onAppear {
                if selectedParticipantIDs.isEmpty {
                    selectedParticipantIDs = Set(familyStore.members.map(\.id))
                }
            }
        }
    }

    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        FamilyMoneyFormatter.cents(from: targetAmount) != nil &&
        !selectedParticipantIDs.isEmpty
    }

    private func toggle(_ id: UUID) {
        if selectedParticipantIDs.contains(id) {
            selectedParticipantIDs.remove(id)
        } else {
            selectedParticipantIDs.insert(id)
        }
    }
}

private enum FamilyGoalSheet: String, Identifiable {
    case contribution
    case gift
    case foundMoney
    case roundUp
    case reminder

    var id: String { rawValue }
}

private struct FamilyGoalDetailView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyStore: FamilyCommunityStore

    let goalID: UUID

    @State private var activeSheet: FamilyGoalSheet?
    @State private var isShowingDeleteConfirmation = false
    @State private var showGoalReachedCelebration = false
    @State private var showProgressCelebration = false

    var body: some View {
        Group {
            if let goal = familyStore.goal(id: goalID) {
                ZStack {
                    MoneyMuncherScreenBackground()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            goalHeader(goal)
                            actionGrid(goal)
                            roundUpCard(goal)
                            reminderCard(goal)
                            goalUpdates(goal)
                        }
                        .padding(20)
                    }

                    if showProgressCelebration {
                        ProgressAddedOverlay(reduceMotion: reduceMotion)
                            .transition(.scale(scale: 0.75).combined(with: .opacity))
                            .zIndex(1)
                    }

                    if showGoalReachedCelebration {
                        GoalReachedCelebrationOverlay(
                            goalTitle: goal.title,
                            reduceMotion: reduceMotion
                        ) {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                                showGoalReachedCelebration = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(2)
                    }
                }
                .navigationTitle(goal.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(role: .destructive) {
                                isShowingDeleteConfirmation = true
                            } label: {
                                Label("Delete Goal", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .contribution:
                        FamilyContributionView(goalID: goalID, source: .manual, onSaved: contributionSaved)
                    case .gift:
                        FamilyContributionView(goalID: goalID, source: .gift, onSaved: contributionSaved)
                    case .foundMoney:
                        FamilyContributionView(goalID: goalID, source: .foundMoney, onSaved: contributionSaved)
                    case .roundUp:
                        FamilyRoundUpView(goalID: goalID, onSaved: contributionSaved)
                    case .reminder:
                        FamilyGoalReminderView(goalID: goalID, reminder: goal.reminder)
                    }
                }
                .confirmationDialog("Delete this goal?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
                    Button("Delete Goal", role: .destructive) {
                        familyStore.deleteGoal(id: goalID)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Its contribution history will also be deleted from this device.")
                }
            } else {
                Text("This goal is no longer available.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func goalHeader(_ goal: FamilyGoal) -> some View {
        VStack(spacing: 16) {
            Text(goal.emoji)
                .font(.system(size: 54))

            VStack(spacing: 4) {
                Text(FamilyMoneyFormatter.string(cents: goal.savedInCents))
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MoneyMuncherDesign.ink)
                Text("of \(FamilyMoneyFormatter.string(cents: goal.targetInCents))")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            GoalProgressBar(progress: goal.progress)
                .frame(height: 18)

            Text(goal.isComplete ? "Goal reached!" : "\(FamilyMoneyFormatter.string(cents: goal.remainingInCents)) to go")
                .font(.headline)
                .foregroundStyle(goal.isComplete ? Color.green : Color.secondary)

            HStack(spacing: -5) {
                ForEach(goal.participantIDs, id: \.self) { id in
                    if let member = familyStore.member(id: id) {
                        Text(member.avatar)
                            .font(.title3)
                            .frame(width: 38, height: 38)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.secondary.opacity(0.2)))
                            .accessibilityLabel(member.name)
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.91, green: 0.98, blue: 0.82), Color(red: 1.0, green: 0.95, blue: 0.80)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: MoneyMuncherDesign.gold.opacity(0.14), radius: 12, y: 6)
    }

    private func actionGrid(_ goal: FamilyGoal) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                GoalActionButton(title: "Record Money", systemImage: "plus.circle.fill") {
                    activeSheet = .contribution
                }
                GoalActionButton(title: "Found Money", systemImage: "sparkles") {
                    activeSheet = .foundMoney
                }
            }

            if goal.kind == .giftPool {
                HStack(spacing: 10) {
                    GoalActionButton(title: "Record Gift", systemImage: "gift.fill") {
                        activeSheet = .gift
                    }

                    ShareLink(item: shareMessage(for: goal)) {
                        Label("Invite Family", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .foregroundStyle(Color(red: 0.04, green: 0.35, blue: 0.30))
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                Text("Sharing sends an invitation, not a payment link. Record gifts here after receiving them through your chosen method.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func roundUpCard(_ goal: FamilyGoal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(
                get: { goal.roundUpTrackingEnabled },
                set: { familyStore.setRoundUpTracking(goalID: goalID, isEnabled: $0) }
            )) {
                Label("Round-up tracking", systemImage: "arrow.up.circle.fill")
                    .font(.headline)
            }

            Text("Log a purchase and Money Muncher will calculate the change to the next dollar. This tracks progress only—no bank transfer occurs.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if goal.roundUpTrackingEnabled {
                Button {
                    activeSheet = .roundUp
                } label: {
                    Label("Log a Purchase", systemImage: "cart.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .padding(16)
        .moneyMuncherCard()
    }

    private func reminderCard(_ goal: FamilyGoal) -> some View {
        Button {
            activeSheet = .reminder
        } label: {
            HStack(spacing: 14) {
                MoneyMuncherIconBadge(
                    systemImage: goal.reminder == nil ? "bell" : "bell.badge.fill",
                    foreground: MoneyMuncherDesign.green,
                    background: Color(red: 0.88, green: 0.96, blue: 0.89)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Follow-up Reminder")
                        .font(.headline)
                        .foregroundStyle(MoneyMuncherDesign.ink)
                    Text(goal.reminder?.summary ?? "Off · Tap to choose a schedule")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .moneyMuncherCard()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens family goal notification settings")
    }

    private func goalUpdates(_ goal: FamilyGoal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Goal Updates", systemImage: "clock.arrow.circlepath")
                .font(.headline.weight(.heavy))
                .foregroundStyle(MoneyMuncherDesign.ink)

            if goal.contributions.isEmpty {
                HStack(spacing: 12) {
                    MoneyMuncherCharacterBadge(
                        imageName: "SammyUnicorn",
                        size: 40,
                        tint: MoneyMuncherDesign.purpleLight
                    )
                    Text("Contributions and celebrations will appear here for everyone using this device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .moneyMuncherCard()
            } else {
                ForEach(goal.contributions.sorted { $0.createdAt > $1.createdAt }) { contribution in
                    ContributionBubble(contribution: contribution)
                }
            }
        }
    }

    private func shareMessage(for goal: FamilyGoal) -> String {
        "Help us reach \(goal.emoji) \(goal.title)! Our family has saved \(FamilyMoneyFormatter.string(cents: goal.savedInCents)) of \(FamilyMoneyFormatter.string(cents: goal.targetInCents)). Message us if you would like to contribute."
    }

    private func contributionSaved(didReachGoal: Bool) {
        activeSheet = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        if didReachGoal {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                    showGoalReachedCelebration = true
                }
            }
        } else {
            withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.62)) {
                showProgressCelebration = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) {
                    showProgressCelebration = false
                }
            }
        }
    }
}

private struct ProgressAddedOverlay: View {
    let reduceMotion: Bool
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(MoneyMuncherDesign.gold)
                    .frame(width: 62, height: 62)
                    .shadow(color: MoneyMuncherDesign.gold.opacity(0.35), radius: 10, y: 5)
                Image(systemName: "dollarsign")
                    .font(.title.weight(.black))
                    .foregroundStyle(Color(red: 0.38, green: 0.25, blue: 0.04))
            }
            .rotationEffect(.degrees(isVisible ? 0 : -18))
            .offset(y: isVisible ? 0 : 24)

            Text("Progress added!")
                .font(.headline.weight(.heavy))
                .foregroundStyle(MoneyMuncherDesign.ink)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.58)) {
                    isVisible = true
                }
            }
        }
    }
}

private struct GoalReachedCelebrationOverlay: View {
    let goalTitle: String
    let reduceMotion: Bool
    let onDismiss: () -> Void

    @State private var burst = false

    private let particles: [(x: CGFloat, y: CGFloat, rotation: Double)] = [
        (-126, -190, -24), (-76, -220, 18), (-20, -202, -12), (52, -216, 28), (118, -174, -20),
        (-132, -86, 20), (132, -76, -28), (-112, 42, -16), (120, 54, 22), (-62, 108, 14), (74, 112, -18)
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            ForEach(Array(particles.enumerated()), id: \.offset) { index, particle in
                Image(systemName: index.isMultiple(of: 2) ? "sparkles" : "circle.fill")
                    .font(index.isMultiple(of: 2) ? .title2 : .caption)
                    .foregroundStyle(index.isMultiple(of: 3) ? MoneyMuncherDesign.gold : MoneyMuncherDesign.mint)
                    .offset(
                        x: burst ? particle.x : 0,
                        y: burst ? particle.y : 0
                    )
                    .rotationEffect(.degrees(burst ? particle.rotation : 0))
                    .opacity(burst ? 0.30 : 1)
            }

            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 74))
                    .scaleEffect(burst ? 1 : 0.65)

                Text("Goal reached!")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(MoneyMuncherDesign.ink)

                Text("Your family filled the progress bar for \(goalTitle).")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button("Celebrate") {
                    onDismiss()
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
            .padding(26)
            .frame(maxWidth: 330)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: .black.opacity(0.20), radius: 24, y: 12)
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if reduceMotion {
                burst = true
            } else {
                withAnimation(.easeOut(duration: 0.9)) {
                    burst = true
                }
            }
        }
    }
}

private struct GoalActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 0.04, green: 0.43, blue: 0.36))
    }
}

private struct ContributionBubble: View {
    let contribution: FamilyGoalContribution

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: contribution.source.systemImage)
                .font(.headline)
                .frame(width: 38, height: 38)
                .foregroundStyle(Color(red: 0.05, green: 0.46, blue: 0.39))
                .background(Color(red: 0.88, green: 0.96, blue: 0.89))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(contribution.contributorName)
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Text(FamilyMoneyFormatter.string(cents: contribution.amountInCents))
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.04, green: 0.43, blue: 0.36))
                }

                Text(contribution.source.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if !contribution.note.isEmpty {
                    Text(contribution.note)
                        .font(.subheadline)
                }

                Text(contribution.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct FamilyContributionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyStore: FamilyCommunityStore

    let goalID: UUID
    let source: FamilyContributionSource
    let onSaved: (Bool) -> Void

    @State private var amount = ""
    @State private var contributorName = ""
    @State private var note = ""
    @State private var selectedMemberID: UUID?
    @State private var celebrationAmountInCents: Int?
    @State private var didReachGoal = false

    var body: some View {
        NavigationStack {
            Group {
                if let celebrationAmountInCents {
                    foundMoneyCelebration(amountInCents: celebrationAmountInCents)
                } else {
                    Form {
                        Section(source.title) {
                            TextField("Amount", text: $amount)
                                .keyboardType(.decimalPad)

                            if source == .gift {
                                TextField("Relative or contributor name", text: $contributorName)
                            } else {
                                Picker("Who found or added it?", selection: $selectedMemberID) {
                                    Text("Whole family").tag(UUID?.none)
                                    ForEach(participantMembers) { member in
                                        Text("\(member.avatar) \(member.name)").tag(Optional(member.id))
                                    }
                                }
                            }

                            TextField(notePlaceholder, text: $note, axis: .vertical)
                                .lineLimit(2...4)
                        }

                        if source == .foundMoney {
                            Section {
                                Label("Use this when a category comes in under budget. The amount is added to goal progress; no money moves automatically.", systemImage: "sparkles")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Section {
                            Text("This updates locally tracked progress only. Money Muncher does not charge, withdraw, or transfer funds.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(source.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(celebrationAmountInCents == nil ? "Cancel" : "Done") {
                        if celebrationAmountInCents == nil {
                            dismiss()
                        } else {
                            onSaved(didReachGoal)
                        }
                    }
                }

                if celebrationAmountInCents == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { save() }
                            .disabled(!canSave)
                    }
                }
            }
        }
    }

    private var notePlaceholder: String {
        switch source {
        case .manual: return "Optional family message"
        case .gift: return "Birthday or holiday message"
        case .foundMoney: return "Category, like Groceries"
        case .roundUp: return "Optional note"
        }
    }

    private var canSave: Bool {
        FamilyMoneyFormatter.cents(from: amount) != nil &&
        (source != .gift || !contributorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func save() {
        guard let cents = FamilyMoneyFormatter.cents(from: amount) else { return }
        let wasComplete = familyStore.goal(id: goalID)?.isComplete == true
        let savedContribution: FamilyGoalContribution?
        if source == .foundMoney {
            savedContribution = familyStore.recordBudgetSurplus(
                goalID: goalID,
                category: note,
                amountInCents: cents,
                memberID: selectedMemberID
            )
        } else {
            savedContribution = familyStore.addContribution(
                goalID: goalID,
                amountInCents: cents,
                memberID: selectedMemberID,
                contributorName: contributorName,
                note: note,
                source: source
            )
        }
        guard savedContribution != nil else { return }

        let reachedNow = !wasComplete && familyStore.goal(id: goalID)?.isComplete == true
        didReachGoal = reachedNow
        if source == .foundMoney {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.68)) {
                celebrationAmountInCents = cents
            }
        } else {
            onSaved(reachedNow)
        }
    }

    private func foundMoneyCelebration(amountInCents: Int) -> some View {
        VStack(spacing: 20) {
            Text("🎉")
                .font(.system(size: 86))
                .transition(.scale.combined(with: .opacity))
            Text("Found money!")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
            Text("\(FamilyMoneyFormatter.string(cents: amountInCents)) was swept into the goal tracker.")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("Progress only—no bank transfer was made.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.91, green: 0.98, blue: 0.82), Color(red: 1.0, green: 0.95, blue: 0.80)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var participantMembers: [FamilyMember] {
        guard let goal = familyStore.goal(id: goalID) else { return [] }
        return goal.participantIDs.compactMap(familyStore.member(id:))
    }
}

private struct FamilyRoundUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyStore: FamilyCommunityStore

    let goalID: UUID
    let onSaved: (Bool) -> Void

    @State private var purchaseAmount = ""
    @State private var selectedMemberID: UUID?
    @State private var savedRoundUpInCents: Int?
    @State private var didReachGoal = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Purchase") {
                    TextField("Purchase amount", text: $purchaseAmount)
                        .keyboardType(.decimalPad)
                    Picker("Shopper", selection: $selectedMemberID) {
                        Text("Whole family").tag(UUID?.none)
                        ForEach(participantMembers) { member in
                            Text("\(member.avatar) \(member.name)").tag(Optional(member.id))
                        }
                    }
                }

                Section("Round-up") {
                    HStack {
                        Text("Add to goal")
                        Spacer()
                        Text(roundUpPreview.map(FamilyMoneyFormatter.string(cents:)) ?? "$0")
                            .font(.title3.bold())
                            .foregroundStyle(Color(red: 0.04, green: 0.43, blue: 0.36))
                    }
                    Text("This records the calculated change in the tracker. It does not charge a card or transfer funds.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let savedRoundUpInCents {
                    Section {
                        Label("Nice! \(FamilyMoneyFormatter.string(cents: savedRoundUpInCents)) joined the family goal.", systemImage: "sparkles")
                            .foregroundStyle(Color(red: 0.04, green: 0.43, blue: 0.36))
                    }
                }
            }
            .navigationTitle("Track a Round-Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(savedRoundUpInCents == nil ? "Cancel" : "Done") {
                        if savedRoundUpInCents == nil {
                            dismiss()
                        } else {
                            onSaved(didReachGoal)
                        }
                    }
                }
                if savedRoundUpInCents == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { save() }
                            .disabled(roundUpPreview == nil)
                    }
                }
            }
        }
    }

    private var roundUpPreview: Int? {
        guard let purchase = FamilyMoneyFormatter.cents(from: purchaseAmount) else { return nil }
        let roundUp = (100 - (purchase % 100)) % 100
        return roundUp > 0 ? roundUp : nil
    }

    private func save() {
        let wasComplete = familyStore.goal(id: goalID)?.isComplete == true
        guard let purchase = FamilyMoneyFormatter.cents(from: purchaseAmount),
              let saved = familyStore.addRoundUp(
                goalID: goalID,
                purchaseAmountInCents: purchase,
                memberID: selectedMemberID
              ) else { return }
        didReachGoal = !wasComplete && familyStore.goal(id: goalID)?.isComplete == true
        savedRoundUpInCents = saved
    }

    private var participantMembers: [FamilyMember] {
        guard let goal = familyStore.goal(id: goalID) else { return [] }
        return goal.participantIDs.compactMap(familyStore.member(id:))
    }
}
