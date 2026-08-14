import CryptoKit
import Security
import SwiftUI

enum ParentAuthenticationResult {
    case success
    case invalid(remainingAttempts: Int)
    case locked(secondsRemaining: Int)
}

@MainActor
final class ParentAccessManager: ObservableObject {
    static let shared = ParentAccessManager()

    @Published private(set) var isUnlocked = false
    @Published private(set) var sessionExpiresAt: Date?

    private let sessionLength: TimeInterval = 5 * 60
    private let maximumAttempts = 5
    private let lockoutLength: TimeInterval = 60
    private let defaults = UserDefaults.standard
    private let failedAttemptsKey = "moneyMuncher.parentAccess.failedAttempts.v1"
    private let lockoutUntilKey = "moneyMuncher.parentAccess.lockoutUntil.v1"

    var hasPIN: Bool { ParentPINKeychain.load() != nil }

    func createPIN(_ pin: String) -> Bool {
        guard Self.isValidPIN(pin) else { return false }

        var salt = Data(count: 16)
        let result = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 16, bytes.baseAddress!)
        }
        guard result == errSecSuccess else { return false }

        let record = ParentPINRecord(salt: salt, digest: Self.digest(pin: pin, salt: salt))
        guard ParentPINKeychain.save(record) else { return false }

        clearFailures()
        beginSession()
        return true
    }

    func authenticate(pin: String, now: Date = Date()) -> ParentAuthenticationResult {
        let lockedFor = lockoutSecondsRemaining(at: now)
        guard lockedFor == 0 else { return .locked(secondsRemaining: lockedFor) }
        guard let record = ParentPINKeychain.load() else {
            return .invalid(remainingAttempts: maximumAttempts)
        }

        let candidate = Self.digest(pin: pin, salt: record.salt)
        guard Self.constantTimeEqual(candidate, record.digest) else {
            let attempts = defaults.integer(forKey: failedAttemptsKey) + 1
            if attempts >= maximumAttempts {
                defaults.set(0, forKey: failedAttemptsKey)
                let lockoutUntil = now.addingTimeInterval(lockoutLength)
                defaults.set(lockoutUntil, forKey: lockoutUntilKey)
                return .locked(secondsRemaining: Int(lockoutLength))
            }

            defaults.set(attempts, forKey: failedAttemptsKey)
            return .invalid(remainingAttempts: maximumAttempts - attempts)
        }

        clearFailures()
        beginSession(now: now)
        return .success
    }

    @discardableResult
    func refreshSession(now: Date = Date()) -> Bool {
        guard isUnlocked, let sessionExpiresAt, sessionExpiresAt > now else {
            lock()
            return false
        }
        return true
    }

    func lock() {
        isUnlocked = false
        sessionExpiresAt = nil
    }

    func lockoutSecondsRemaining(at date: Date = Date()) -> Int {
        guard let lockoutUntil = defaults.object(forKey: lockoutUntilKey) as? Date else { return 0 }
        let remaining = Int(ceil(lockoutUntil.timeIntervalSince(date)))
        if remaining <= 0 {
            defaults.removeObject(forKey: lockoutUntilKey)
            return 0
        }
        return remaining
    }

    static func isValidPIN(_ pin: String) -> Bool {
        pin.count == 6 && pin.allSatisfy(\.isNumber)
    }

    private func beginSession(now: Date = Date()) {
        isUnlocked = true
        sessionExpiresAt = now.addingTimeInterval(sessionLength)
    }

    private func clearFailures() {
        defaults.removeObject(forKey: failedAttemptsKey)
        defaults.removeObject(forKey: lockoutUntilKey)
    }

    private static func digest(pin: String, salt: Data) -> Data {
        var input = salt
        input.append(contentsOf: pin.utf8)
        return Data(SHA256.hash(data: input))
    }

    private static func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).reduce(UInt8(0)) { result, pair in result | (pair.0 ^ pair.1) } == 0
    }
}

private struct ParentPINRecord: Codable {
    let salt: Data
    let digest: Data
}

private enum ParentPINKeychain {
    private static let service = "ca.moneymuncher.app.parent-access"
    private static let account = "parent-pin-v1"

    static func load() -> ParentPINRecord? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(ParentPINRecord.self, from: data)
    }

    static func save(_ record: ParentPINRecord) -> Bool {
        guard let data = try? JSONEncoder().encode(record) else { return false }
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(baseQuery as CFDictionary, update as CFDictionary)
        if status == errSecSuccess { return true }
        guard status == errSecItemNotFound else { return false }

        var item = baseQuery
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

private enum ParentGatePhase {
    case adultCheck
    case createPIN
    case confirmPIN
    case unlock
}

private struct AdultChallenge {
    let left: Int
    let right: Int
    var prompt: String { "What is \(left) × \(right)?" }
    var answer: String { String(left * right) }

    static func make() -> AdultChallenge {
        AdultChallenge(left: Int.random(in: 12...19), right: Int.random(in: 6...9))
    }
}

struct ParentGateView: View {
    @ObservedObject var access: ParentAccessManager
    let onUnlock: () -> Void
    let onCancel: () -> Void

    @State private var phase: ParentGatePhase = .adultCheck
    @State private var challenge = AdultChallenge.make()
    @State private var challengeAnswer = ""
    @State private var pin = ""
    @State private var firstPIN = ""
    @State private var errorMessage: String?
    @State private var now = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: phase == .unlock ? "lock.shield.fill" : "person.badge.key.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Color(red: 0.05, green: 0.46, blue: 0.39))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.largeTitle.bold())
                        Text(message)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    inputSection

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(action: continueTapped) {
                        Text(primaryButtonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Color(red: 0.04, green: 0.43, blue: 0.36))
                    .disabled(isLockedOut)

                    if phase == .unlock {
                        Label("Parent mode locks after five minutes and whenever the app leaves the screen.", systemImage: "timer")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Parent Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .onAppear {
            phase = access.hasPIN ? .unlock : .adultCheck
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
    }

    @ViewBuilder
    private var inputSection: some View {
        switch phase {
        case .adultCheck:
            VStack(alignment: .leading, spacing: 8) {
                Text(challenge.prompt).font(.headline)
                TextField("Answer", text: numericBinding($challengeAnswer, limit: 4))
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
        case .createPIN, .confirmPIN, .unlock:
            VStack(alignment: .leading, spacing: 8) {
                Text(pinPrompt).font(.headline)
                SecureField("6-digit PIN", text: numericBinding($pin, limit: 6))
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                if isLockedOut {
                    Text("Too many attempts. Try again in \(lockoutSeconds) seconds.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var title: String {
        switch phase {
        case .adultCheck: return "Grown-up setup"
        case .createPIN: return "Create a Parent PIN"
        case .confirmPIN: return "Confirm your PIN"
        case .unlock: return "Parent Check"
        }
    }

    private var message: String {
        switch phase {
        case .adultCheck:
            return "Complete this one-time grown-up check before choosing the PIN that protects family controls."
        case .createPIN:
            return "Choose six digits a child cannot easily guess. Avoid birthdays, repeated digits, and simple sequences."
        case .confirmPIN:
            return "Enter the same six digits again. The PIN stays securely on this device."
        case .unlock:
            return "Enter the Parent PIN to manage quests, rewards, accounts, and grown-up links."
        }
    }

    private var pinPrompt: String {
        switch phase {
        case .createPIN: return "New Parent PIN"
        case .confirmPIN: return "Re-enter Parent PIN"
        case .unlock: return "Parent PIN"
        case .adultCheck: return ""
        }
    }

    private var primaryButtonTitle: String {
        switch phase {
        case .adultCheck, .createPIN: return "Continue"
        case .confirmPIN: return "Create PIN"
        case .unlock: return isLockedOut ? "Temporarily Locked" : "Unlock Parent Mode"
        }
    }

    private var lockoutSeconds: Int { access.lockoutSecondsRemaining(at: now) }
    private var isLockedOut: Bool { phase == .unlock && lockoutSeconds > 0 }

    private func continueTapped() {
        errorMessage = nil
        switch phase {
        case .adultCheck:
            guard challengeAnswer.trimmingCharacters(in: .whitespacesAndNewlines) == challenge.answer else {
                challenge = .make()
                challengeAnswer = ""
                errorMessage = "That answer wasn’t correct. Ask a grown-up to continue."
                return
            }
            phase = .createPIN

        case .createPIN:
            guard ParentAccessManager.isValidPIN(pin) else {
                errorMessage = "Enter exactly six digits."
                return
            }
            guard Set(pin).count > 2, pin != "123456", pin != "654321" else {
                errorMessage = "Choose a less predictable PIN."
                return
            }
            firstPIN = pin
            pin = ""
            phase = .confirmPIN

        case .confirmPIN:
            guard pin == firstPIN else {
                pin = ""
                firstPIN = ""
                phase = .createPIN
                errorMessage = "The PINs didn’t match. Please choose your PIN again."
                return
            }
            guard access.createPIN(pin) else {
                errorMessage = "The PIN couldn’t be saved securely. Please try again."
                return
            }
            onUnlock()

        case .unlock:
            switch access.authenticate(pin: pin, now: now) {
            case .success:
                onUnlock()
            case .invalid(let remainingAttempts):
                pin = ""
                errorMessage = "Incorrect PIN. \(remainingAttempts) attempt\(remainingAttempts == 1 ? "" : "s") remaining."
            case .locked(let secondsRemaining):
                pin = ""
                errorMessage = "Too many incorrect attempts. Parent access is locked for \(secondsRemaining) seconds."
            }
        }
    }

    private func numericBinding(_ binding: Binding<String>, limit: Int) -> Binding<String> {
        Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                binding.wrappedValue = String(newValue.filter(\.isNumber).prefix(limit))
            }
        )
    }
}
