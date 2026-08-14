import SwiftUI
import UIKit

struct FamilyGoalReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var familyStore: FamilyCommunityStore
    @EnvironmentObject private var notificationManager: FamilyNotificationManager

    let goalID: UUID

    @State private var kind: FamilyGoalReminderKind
    @State private var weekday: Int
    @State private var reminderTime: Date
    @State private var inactivityDays: Int
    @State private var isWorking = false
    @State private var activeAlert: ReminderAlert?

    init(goalID: UUID, reminder: FamilyGoalReminder?) {
        self.goalID = goalID

        let currentReminder = reminder ?? FamilyGoalReminder(kind: .weekly)
        _kind = State(initialValue: currentReminder.kind)
        _weekday = State(initialValue: currentReminder.weekday)
        _inactivityDays = State(initialValue: currentReminder.inactivityDays)

        var timeComponents = DateComponents()
        timeComponents.hour = currentReminder.hour
        timeComponents.minute = currentReminder.minute
        _reminderTime = State(initialValue: Calendar.current.date(from: timeComponents) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Follow-up Type") {
                    Picker("Reminder", selection: $kind) {
                        ForEach(FamilyGoalReminderKind.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    if kind == .weekly {
                        Picker("Day", selection: $weekday) {
                            ForEach(Array(Calendar.current.weekdaySymbols.enumerated()), id: \.offset) { index, name in
                                Text(name).tag(index + 1)
                            }
                        }

                        DatePicker(
                            "Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    } else {
                        Stepper(value: $inactivityDays, in: 1...30) {
                            Text(inactivityDays == 1 ? "After 1 day" : "After \(inactivityDays) days")
                        }
                    }
                }

                Section("Schedule") {
                    Label(draftReminder.summary, systemImage: kind == .weekly ? "calendar.badge.clock" : "clock.arrow.circlepath")
                    Text(notificationManager.authorizationSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Test on This Device") {
                    Button {
                        sendTestNotification()
                    } label: {
                        HStack {
                            Label("Send Test in 10 Seconds", systemImage: "bell.badge.fill")
                            Spacer()
                            if isWorking {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isWorking)

                    Text("The test banner also appears while Money Muncher is open, so you can verify it immediately.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let testStatusMessage = notificationManager.testStatusMessage {
                        Label(testStatusMessage, systemImage: "info.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                if familyStore.goal(id: goalID)?.reminder != nil {
                    Section {
                        Button("Turn Off Reminder", role: .destructive) {
                            familyStore.setGoalReminder(goalID: goalID, reminder: nil)
                            notificationManager.cancelReminder(goalID: goalID)
                            dismiss()
                        }
                    }
                }

                Section {
                    Text("Reminder text is intentionally private and does not show names, balances, goal titles, or contribution amounts on the lock screen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Goal Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveReminder() }
                        .disabled(isWorking)
                }
            }
            .task {
                await notificationManager.refreshAuthorizationStatus()
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .permissionDenied:
                    return Alert(
                        title: Text("Notifications Are Off"),
                        message: Text("Allow notifications in Settings to enable family goal reminders."),
                        primaryButton: .default(Text("Open Settings")) {
                            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                            openURL(settingsURL)
                        },
                        secondaryButton: .cancel()
                    )
                case .testScheduled:
                    return Alert(
                        title: Text("Test Scheduled"),
                        message: Text("A Money Muncher test notification will appear in about 10 seconds."),
                        dismissButton: .default(Text("OK"))
                    )
                case .scheduleFailed:
                    return Alert(
                        title: Text("Could Not Schedule Reminder"),
                        message: Text(notificationManager.lastErrorMessage ?? "Please try again."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }

    private var draftReminder: FamilyGoalReminder {
        let time = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        return FamilyGoalReminder(
            kind: kind,
            weekday: weekday,
            hour: time.hour ?? 18,
            minute: time.minute ?? 0,
            inactivityDays: inactivityDays
        )
    }

    private func saveReminder() {
        isWorking = true
        Task {
            guard await notificationManager.requestAuthorization() else {
                isWorking = false
                activeAlert = .permissionDenied
                return
            }

            familyStore.setGoalReminder(goalID: goalID, reminder: draftReminder)
            guard let goal = familyStore.goal(id: goalID),
                  await notificationManager.scheduleReminder(for: goal) else {
                isWorking = false
                activeAlert = .scheduleFailed
                return
            }

            isWorking = false
            dismiss()
        }
    }

    private func sendTestNotification() {
        isWorking = true
        Task {
            let scheduled = await notificationManager.scheduleTestNotification()
            isWorking = false
            if scheduled {
                activeAlert = .testScheduled
            } else if notificationManager.authorizationStatus == .denied {
                activeAlert = .permissionDenied
            } else {
                activeAlert = .scheduleFailed
            }
        }
    }
}

private enum ReminderAlert: String, Identifiable {
    case permissionDenied
    case testScheduled
    case scheduleFailed

    var id: String { rawValue }
}
