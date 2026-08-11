import SwiftUI

struct FamilyCommunityView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var familyStore: FamilyCommunityStore

    @State private var isShowingAddMember = false
    @State private var isShowingNewActivity = false
    @State private var isShowingPaywall = false
    @State private var addMemberAfterUpgrade = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    familySection
                    FamilyGoalsSection()
                    activitySection
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Family Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
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
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "house.and.flag.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(Color(red: 0.05, green: 0.46, blue: 0.39))

            Text("Learn and grow together")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.05, green: 0.26, blue: 0.23))

            Text("Create child profiles, grow shared goals, choose activities, and celebrate progress as a family.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Label("Saved only on this device", systemImage: "iphone.gen3")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
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
                emptyCard(
                    systemImage: "person.2.fill",
                    title: "Add your first child profile",
                    message: "Profiles keep each child's activity progress separate."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(familyStore.members) { member in
                        FamilyMemberRow(member: member) {
                            familyStore.removeMember(id: member.id)
                        }
                    }
                }
            }
        }
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

            if familyStore.members.isEmpty {
                emptyCard(
                    systemImage: "checklist",
                    title: "Profiles come first",
                    message: "Add at least one child before creating a shared activity."
                )
            } else if familyStore.activities.isEmpty {
                emptyCard(
                    systemImage: "flag.checkered",
                    title: "Create a family activity",
                    message: "Try a savings goal, grocery budget, or no-spend challenge."
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
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.05, green: 0.26, blue: 0.23))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: action) {
                Label(actionTitle, systemImage: actionSystemImage)
                    .font(.subheadline.weight(.bold))
            }
            .disabled(title == "Shared Activities" && familyStore.members.isEmpty)
        }
    }

    private func emptyCard(systemImage: String, title: String, message: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2.weight(.bold))
                .frame(width: 44, height: 44)
                .foregroundStyle(Color(red: 0.05, green: 0.46, blue: 0.39))
                .background(Color(red: 0.88, green: 0.96, blue: 0.89))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(message)
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
                .background(Color(red: 0.90, green: 0.96, blue: 0.99))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(member.name)
                    .font(.headline)
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
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct FamilyActivityRow: View {
    let activity: FamilyActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(activity.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: activity.isComplete ? "checkmark.seal.fill" : "chevron.right")
                    .foregroundStyle(activity.isComplete ? Color.green : Color.secondary)
            }

            ProgressView(value: activity.progress)
                .tint(Color(red: 0.05, green: 0.46, blue: 0.39))

            Text("\(activity.completedParticipantIDs.count) of \(activity.participantIDs.count) participants complete")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                            } label: {
                                Text(avatar)
                                    .font(.system(size: 30))
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(selectedAvatar == avatar ? Color.green.opacity(0.18) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(selectedAvatar == avatar ? Color.green : Color.secondary.opacity(0.25), lineWidth: 2)
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
                                    } label: {
                                        HStack(spacing: 12) {
                                            Text(member.avatar).font(.title2)
                                            Text(member.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                                                .font(.title2)
                                                .foregroundStyle(isComplete ? Color.green : Color.secondary)
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
