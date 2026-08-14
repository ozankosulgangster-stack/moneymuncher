import UIKit
import UserNotifications

extension Notification.Name {
    static let moneyMuncherLocalNotificationPresented = Notification.Name(
        "MoneyMuncherLocalNotificationPresented"
    )
}

final class MoneyMuncherNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        NotificationCenter.default.post(
            name: .moneyMuncherLocalNotificationPresented,
            object: notification.request.identifier
        )
        completionHandler([.banner, .sound])
    }
}

@MainActor
final class FamilyNotificationManager: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var testStatusMessage: String?

    private static let goalIdentifierPrefix = "family-goal-reminder-goal-"
    private static let legacyGoalIdentifierPrefix = "family-goal-reminder-"
    private static let testIdentifierPrefix = "family-goal-test-"
    private let center: UNUserNotificationCenter
    private var presentedObserver: NSObjectProtocol?

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        let testIdentifierPrefix = Self.testIdentifierPrefix
        presentedObserver = NotificationCenter.default.addObserver(
            forName: .moneyMuncherLocalNotificationPresented,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let identifier = notification.object as? String,
                  identifier.hasPrefix(testIdentifierPrefix) else {
                return
            }

            Task { @MainActor [weak self] in
                self?.testStatusMessage = "Delivered by iOS while Money Muncher was open."
            }
        }
    }

    deinit {
        if let presentedObserver {
            NotificationCenter.default.removeObserver(presentedObserver)
        }
    }

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    var authorizationSummary: String {
        switch authorizationStatus {
        case .notDetermined: return "Permission not requested"
        case .denied: return "Notifications are off in Settings"
        case .authorized: return "Notifications are allowed"
        case .provisional: return "Notifications are delivered quietly"
        case .ephemeral: return "Notifications are temporarily allowed"
        @unknown default: return "Notification status unavailable"
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        await refreshAuthorizationStatus()

        if isAuthorized {
            return true
        }

        guard authorizationStatus != .denied else {
            return false
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            await refreshAuthorizationStatus()
            return granted && isAuthorized
        } catch {
            lastErrorMessage = "Notification permission could not be requested."
            return false
        }
    }

    func reconcile(goals: [FamilyGoal]) async {
        await refreshAuthorizationStatus()

        let activeGoals = goals.filter { !$0.isComplete && $0.reminder != nil }
        let activeIdentifiers = Set(activeGoals.map(identifier(for:)))
        let pending = await center.pendingNotificationRequests()
        let staleIdentifiers = pending
            .map(\.identifier)
            .filter { isManagedGoalIdentifier($0) && !activeIdentifiers.contains($0) }
        let delivered = await center.deliveredNotifications()
        let staleDeliveredIdentifiers = delivered
            .map { $0.request.identifier }
            .filter { isManagedGoalIdentifier($0) && !activeIdentifiers.contains($0) }

        if !staleIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)
        }

        if !staleDeliveredIdentifiers.isEmpty {
            center.removeDeliveredNotifications(withIdentifiers: staleDeliveredIdentifiers)
        }

        guard isAuthorized else { return }

        for goal in activeGoals {
            await scheduleReminder(for: goal)
        }
    }

    @discardableResult
    func scheduleReminder(for goal: FamilyGoal) async -> Bool {
        let requestIdentifier = identifier(for: goal)
        center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])

        guard isAuthorized, !goal.isComplete, let reminder = goal.reminder else {
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = "Money Muncher family check-in"
        content.body = "Open the app to check your family goal progress."
        content.sound = .default
        content.threadIdentifier = "family-goals"
        content.userInfo = ["goalID": goal.id.uuidString]

        let trigger: UNNotificationTrigger
        switch reminder.kind {
        case .weekly:
            var components = DateComponents()
            components.calendar = Calendar.current
            components.weekday = reminder.weekday
            components.hour = reminder.hour
            components.minute = reminder.minute
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .inactivity:
            let latestProgressDate = goal.contributions.map(\.createdAt).max() ?? goal.createdAt
            let targetDate = Calendar.current.date(
                byAdding: .day,
                value: reminder.inactivityDays,
                to: latestProgressDate
            ) ?? Date().addingTimeInterval(86_400)
            let interval = max(targetDate.timeIntervalSinceNow, 60)
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: requestIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            lastErrorMessage = nil
            return true
        } catch {
            lastErrorMessage = "The reminder could not be scheduled."
            return false
        }
    }

    func cancelReminder(goalID: UUID) {
        let requestIdentifier = identifier(for: goalID)
        center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [requestIdentifier])
    }

    @discardableResult
    func scheduleTestNotification() async -> Bool {
        guard await requestAuthorization() else { return false }

        let settings = await center.notificationSettings()
        guard settings.alertSetting == .enabled else {
            lastErrorMessage = "Notification alerts are disabled in iPhone Settings."
            testStatusMessage = "Not scheduled: alert banners are disabled."
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = "Money Muncher reminders are ready"
        content.body = "Your family goal follow-ups are working on this device."
        content.sound = .default
        content.threadIdentifier = "family-goals"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let testIdentifier = "\(Self.testIdentifierPrefix)\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: testIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            testStatusMessage = "Asking iOS to schedule the test…"
            try await center.add(request)

            let pending = await center.pendingNotificationRequests()
            guard pending.contains(where: { $0.identifier == testIdentifier }) else {
                lastErrorMessage = "iOS accepted the request but it was not found in the pending queue."
                testStatusMessage = "Not pending after scheduling."
                return false
            }

            lastErrorMessage = nil
            testStatusMessage = "Accepted by iOS and pending for about 10 seconds."
            return true
        } catch {
            lastErrorMessage = "The test notification could not be scheduled: \(error.localizedDescription)"
            testStatusMessage = "Scheduling failed."
            return false
        }
    }

    private func identifier(for goal: FamilyGoal) -> String {
        identifier(for: goal.id)
    }

    private func identifier(for goalID: UUID) -> String {
        "\(Self.goalIdentifierPrefix)\(goalID.uuidString)"
    }

    private func isManagedGoalIdentifier(_ identifier: String) -> Bool {
        if identifier.hasPrefix(Self.goalIdentifierPrefix) {
            return true
        }

        // Remove reminders created by the first local-notification build while
        // keeping test notifications out of goal reconciliation.
        return identifier.hasPrefix(Self.legacyGoalIdentifierPrefix) &&
            !identifier.hasPrefix(Self.testIdentifierPrefix)
    }
}
