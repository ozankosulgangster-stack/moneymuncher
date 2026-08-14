import SwiftUI
import UIKit

struct FamilyCommunityView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var familyStore: FamilyCommunityStore

    @State private var isShowingAddMember = false
    @State private var isShowingNewActivity = false
    @State private var isShowingPaywall = false
    @State private var addMemberAfterUpgrade = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                MoneyMuncherScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        devicePrivacyPill
                        familySection

                        if !familyStore.members.isEmpty {
                            FamilyGoalsSection()
                            activitySection
                            familyTip
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Family Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .tint(MoneyMuncherDesign.green)
                }
            }
            .sheet(isPresented: $isShowingAddMember) {
                AddFamilyMemberView()
                    .environmentObject(familyStore)
            }
            .sheet(isPresented: $isShowingNewActivity) {
                NewFamilyActivityView()
                    .environmentObject(familyStore)
            }
            .sheet(isPresented: $isShowingPaywall, onDismiss: continueAfterUpgrade) {
                PaywallView(
                    primaryActionTitle: "Continue to Add Member",
                    onOpenLessons: {
                        addMemberAfterUpgrade = true
                        isShowingPaywall = false
                    }
                )
                .environmentObject(purchaseManager)
            }
            .onAppear {
                guard !hasAppeared else { return }
                if reduceMotion {
                    hasAppeared = true
                } else {
                    withAnimation(.spring(response: 0.65, dampingFraction: 0.76)) {
                        hasAppeared = true
                    }
                }
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(.white.opacity(0.28))
                .frame(width: 110, height: 110)
                .offset(x: 35, y: 40)

            HStack(alignment: .center, spacing: 15) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.78))
                        .frame(width: 62, height: 62)
                    Image(systemName: "house.and.flag.fill")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundStyle(MoneyMuncherDesign.green)
                }
                .scaleEffect(hasAppeared ? 1 : 0.72)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Learn and grow together")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(MoneyMuncherDesign.ink)

                    Text("Add your crew, set goals, and celebrate progress as a family.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MoneyMuncherDesign.ink.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: -7) {
                MoneyMuncherCharacterBadge(imageName: "DinoTeacher", size: 34, tint: .white.opacity(0.90))
                MoneyMuncherCharacterBadge(imageName: "MiraTurtle", size: 34, tint: .white.opacity(0.90))
                MoneyMuncherCharacterBadge(imageName: "SammyUnicorn", size: 34, tint: .white.opacity(0.90))
            }
            .offset(x: 4, y: 9)
            .opacity(hasAppeared ? 1 : 0)
        }
        .padding(20)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    MoneyMuncherDesign.warmGold,
                    MoneyMuncherDesign.warmPink
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: MoneyMuncherDesign.purple.opacity(0.10), radius: 14, y: 7)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 12)
    }

    private var familySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Child Profiles",
                detail: memberLimitText,
                actionTitle: "Add",
                actionSystemImage: "person.badge.plus"
            ) {
                requestAddMember()
            }

            if familyStore.members.isEmpty {
                onboardingCard
            } else {
                VStack(spacing: 10) {
                    ForEach(familyStore.members) { member in
                        FamilyMemberRow(member: member) {
                            familyStore.removeMember(id: member.id)
                        }
                    }
                }
                .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.78), value: familyStore.members)
            }
        }
    }

    private var devicePrivacyPill: some View {
        Label("Family profiles and progress stay on this device", systemImage: "iphone.gen3")
            .font(.footnote.weight(.bold))
            .foregroundStyle(MoneyMuncherDesign.green)
            .padding(.horizontal, 13)
            .frame(minHeight: 38)
            .background(Color(red: 0.88, green: 0.96, blue: 0.89))
            .clipShape(Capsule())
            .accessibilityHint("No family profile data is uploaded by this feature")
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Shared Activities",
                detail: activitySummary,
                actionTitle: "Create",
                actionSystemImage: "plus"
            ) {
                isShowingNewActivity = true
            }

            if familyStore.activities.isEmpty {
                emptyCard(
                    systemImage: "flag.checkered",
                    title: "Create a family activity",
                    message: "Try a grocery challenge, a no-spend day, or a family money conversation.",
                    imageName: "CaptainJackShark"
                )
            } else {
                if !familyStore.openActivities.isEmpty {
                    activityGroup(title: "In Progress", activities: familyStore.openActivities)
                }

                if !familyStore.completedActivities.isEmpty {
                    activityGroup(title: "Completed", activities: familyStore.completedActivities)
                }
            }
        }
    }

    private func activityGroup(title: String, activities: [FamilyActivity]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)

            ForEach(activities) { activity in
                NavigationLink {
                    FamilyActivityDetailView(activityID: activity.id)
                        .environmentObject(familyStore)
                } label: {
                    FamilyActivityRow(activity: activity)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        if let index = activities.firstIndex(of: activity) {
                            familyStore.deleteActivities(at: IndexSet(integer: index), from: activities)
                        }
                    } label: {
                        Label("Delete Activity", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func sectionHeader(
        title: String,
        detail: String,
        actionTitle: String,
        actionSystemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .textCase(.uppercase)
                    .tracking(0.7)
                    .foregroundStyle(MoneyMuncherDesign.purple)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            MoneyMuncherActionChip(
                title: actionTitle,
                systemImage: actionSystemImage,
                isEnabled: title != "Shared Activities" || !familyStore.members.isEmpty,
                action: action
            )
        }
    }

    private func emptyCard(
        systemImage: String,
        title: String,
        message: String,
        imageName: String = "DinoTeacher"
    ) -> some View {
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

    private var onboardingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 13) {
                MoneyMuncherCharacterBadge(
                    imageName: "DinoTeacher",
                    size: 52,
                    tint: MoneyMuncherDesign.familyGreen
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Start your family journey")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(MoneyMuncherDesign.ink)
                    Text("One quick setup unlocks goals and shared activities.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                journeyStep(number: 1, title: "Add a child profile", isAvailable: true)
                journeyStep(number: 2, title: "Create a family goal", isAvailable: false)
                journeyStep(number: 3, title: "Complete an activity together", isAvailable: false)
            }

            Button {
                requestAddMember()
            } label: {
                Label("Add First Profile", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle())
        }
        .padding(18)
        .moneyMuncherCard()
    }

    private func journeyStep(number: Int, title: String, isAvailable: Bool) -> some View {
        HStack(spacing: 11) {
            Text("\(number)")
                .font(.subheadline.monospacedDigit().weight(.black))
                .foregroundStyle(isAvailable ? .white : MoneyMuncherDesign.purple)
                .frame(width: 30, height: 30)
                .background(isAvailable ? MoneyMuncherDesign.purple : MoneyMuncherDesign.purpleLight)
                .clipShape(Circle())

            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isAvailable ? MoneyMuncherDesign.ink : Color.secondary)

            Spacer()

            Image(systemName: isAvailable ? "arrow.right" : "lock.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(isAvailable ? MoneyMuncherDesign.purple : Color.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var familyTip: some View {
        HStack(alignment: .top, spacing: 12) {
            MoneyMuncherIconBadge(
                systemImage: "lightbulb.fill",
                foreground: Color(red: 0.67, green: 0.46, blue: 0.02),
                background: MoneyMuncherDesign.warmGold,
                size: 38
            )
            Text("Small goals work best. Pick one visible win and celebrate every contribution together.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MoneyMuncherDesign.ink.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .background(MoneyMuncherDesign.purpleLight.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var memberLimitText: String {
        if purchaseManager.hasPremiumAccess {
            return "\(familyStore.members.count) profiles · Plus has no limit"
        }
        return "\(familyStore.members.count) of \(FamilyCommunityStore.freeMemberLimit) free profiles"
    }

    private var activitySummary: String {
        let completed = familyStore.completedActivities.count
        return "\(familyStore.openActivities.count) active · \(completed) completed"
    }

    private func requestAddMember() {
        if familyStore.canAddMember(hasPremiumAccess: purchaseManager.hasPremiumAccess) {
            isShowingAddMember = true
        } else {
            addMemberAfterUpgrade = true
            isShowingPaywall = true
        }
    }

    private func continueAfterUpgrade() {
        guard addMemberAfterUpgrade else { return }
        addMemberAfterUpgrade = false

        if purchaseManager.hasPremiumAccess {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isShowingAddMember = true
            }
        }
    }
}

private struct FamilyMemberRow: View {
    let member: FamilyMember
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(member.avatar)
                .font(.system(size: 28))
                .frame(width: 48, height: 48)
                .background(MoneyMuncherDesign.purpleLight)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(member.name)
                    .font(.headline)
                    .foregroundStyle(MoneyMuncherDesign.ink)
                Text("Child profile")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Profile", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Options for \(member.name)")
        }
        .padding(14)
        .moneyMuncherCard()
        .transition(.scale(scale: 0.94).combined(with: .opacity))
    }
}

private struct FamilyActivityRow: View {
    let activity: FamilyActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(activity.title)
                    .font(.headline)
                    .foregroundStyle(MoneyMuncherDesign.ink)
                Spacer()
                Image(systemName: activity.isComplete ? "checkmark.seal.fill" : "chevron.right")
                    .foregroundStyle(activity.isComplete ? Color.green : Color.secondary)
            }

            ProgressView(value: activity.progress)
                .tint(MoneyMuncherDesign.mint)
                .animation(.spring(response: 0.5, dampingFraction: 0.78), value: activity.progress)

            Text("\(activity.completedParticipantIDs.count) of \(activity.participantIDs.count) participants complete")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .moneyMuncherCard()
    }
}

private struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var familyStore: FamilyCommunityStore

    @State private var name = ""
    @State private var selectedAvatar = "🦖"

    private let avatars = ["🦖", "🦉", "🐢", "🦈", "🦄", "🐧", "🦊", "🐼"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Child Profile") {
                    TextField("First name or nickname", text: $name)
                        .textContentType(.givenName)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(avatars, id: \.self) { avatar in
                            Button {
                                selectedAvatar = avatar
                                UISelectionFeedbackGenerator().selectionChanged()
                            } label: {
                                Text(avatar)
                                    .font(.system(size: 30))
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(selectedAvatar == avatar ? MoneyMuncherDesign.purpleLight : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(selectedAvatar == avatar ? MoneyMuncherDesign.purple : Color.secondary.opacity(0.25), lineWidth: 2)
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Choose \(avatar) avatar")
                            .accessibilityAddTraits(selectedAvatar == avatar ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    Text("Profiles and progress stay on this device. Use a nickname if you prefer not to store a child's full name.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Child Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if familyStore.addMember(
                            name: name,
                            avatar: selectedAvatar,
                            hasPremiumAccess: purchaseManager.hasPremiumAccess
                        ) != nil {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct NewFamilyActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyStore: FamilyCommunityStore

    @State private var title = ""
    @State private var note = ""
    @State private var selectedParticipantIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    TextField("Activity title", text: $title)
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Participants") {
                    ForEach(familyStore.members) { member in
                        Button {
                            toggle(member.id)
                        } label: {
                            HStack {
                                Text(member.avatar)
                                Text(member.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: selectedParticipantIDs.contains(member.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedParticipantIDs.contains(member.id) ? Color.green : Color.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if familyStore.addActivity(
                            title: title,
                            note: note,
                            participantIDs: selectedParticipantIDs
                        ) != nil {
                            dismiss()
                        }
                    }
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        selectedParticipantIDs.isEmpty
                    )
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if selectedParticipantIDs.contains(id) {
            selectedParticipantIDs.remove(id)
        } else {
            selectedParticipantIDs.insert(id)
        }
    }
}

private struct FamilyActivityDetailView: View {
    @EnvironmentObject private var familyStore: FamilyCommunityStore
    let activityID: UUID

    var body: some View {
        Group {
            if let activity = familyStore.activity(id: activityID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(activity.isComplete ? "Activity complete!" : "Family progress")
                                .font(.title2.bold())
                            ProgressView(value: activity.progress)
                                .tint(Color(red: 0.05, green: 0.46, blue: 0.39))
                            Text("\(activity.completedParticipantIDs.count) of \(activity.participantIDs.count) finished")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.91, green: 0.98, blue: 0.82))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        if !activity.note.isEmpty {
                            Text(activity.note)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Participants")
                                .font(.headline)

                            ForEach(activity.participantIDs, id: \.self) { memberID in
                                if let member = familyStore.member(id: memberID) {
                                    let isComplete = activity.completedParticipantIDs.contains(memberID)
                                    Button {
                                        familyStore.toggleCompletion(activityID: activityID, memberID: memberID)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    } label: {
                                        HStack(spacing: 12) {
                                            Text(member.avatar).font(.title2)
                                            Text(member.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                                                .font(.title2)
                                                .foregroundStyle(isComplete ? MoneyMuncherDesign.mint : Color.secondary)
                                                .scaleEffect(isComplete ? 1.08 : 1)
                                                .animation(.spring(response: 0.38, dampingFraction: 0.58), value: isComplete)
                                        }
                                        .padding(14)
                                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(member.name), \(isComplete ? "complete" : "not complete")")
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationTitle(activity.title)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.folder")
                        .font(.largeTitle)
                    Text("Activity Not Found")
                        .font(.headline)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
