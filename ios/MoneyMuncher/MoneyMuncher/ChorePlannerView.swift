import Foundation
import SwiftUI

struct ChorePlannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = ChorePlannerStore()
    @State private var isShowingResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Family Chore Planner", systemImage: "checklist.checked")
                            .font(.title2.weight(.black))
                            .foregroundStyle(Color(red: 0.04, green: 0.38, blue: 0.32))

                        Text("Assign dollars or points, celebrate completed chores, and help earned money find a job.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 5)
                }

                Section("Start from a template") {
                    Button {
                        store.loadTemplate(.littleHelper)
                    } label: {
                        TemplateLabel(icon: "🌟", title: "Little Helper", subtitle: "Simple point-based wins")
                    }

                    Button {
                        store.loadTemplate(.allowanceBuilder)
                    } label: {
                        TemplateLabel(icon: "🪙", title: "Allowance Builder", subtitle: "Dollar rewards and saving")
                    }

                    Button {
                        store.loadTemplate(.schoolWeek)
                    } label: {
                        TemplateLabel(icon: "🎒", title: "School Week", subtitle: "Routine-building points")
                    }
                }

                Section {
                    if store.chores.isEmpty {
                        Text("Choose a template or add your first chore. Your plan saves automatically on this device.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach($store.chores) { $chore in
                            ChoreEditorRow(chore: $chore)
                        }
                        .onDelete(perform: store.deleteChores)
                    }

                    Button {
                        store.addChore()
                    } label: {
                        Label("Add chore", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("This week's chores")
                        Spacer()
                        Text("\(store.completedCount)/\(store.chores.count)")
                    }
                } footer: {
                    if !store.chores.isEmpty {
                        ProgressView(value: store.completionProgress)
                            .tint(Color(red: 0.04, green: 0.55, blue: 0.39))
                    }
                }

                Section {
                    SplitStepper(title: "Spend", value: $store.spendPercent, tint: .orange)
                    SplitStepper(title: "Save", value: $store.savePercent, tint: .blue)
                    SplitStepper(title: "Give", value: $store.givePercent, tint: .green)

                    Label {
                        Text(store.hasValidSplit ? "Your split adds to 100%." : "Adjust the split — it currently adds to \(store.splitTotal)%.")
                            .font(.caption.weight(.semibold))
                    } icon: {
                        Image(systemName: store.hasValidSplit ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    }
                    .foregroundStyle(store.hasValidSplit ? Color.green : Color.orange)
                } header: {
                    Text("Split completed dollar rewards")
                } footer: {
                    Text("Point rewards remain points. Change each percentage in 5% steps.")
                }

                Section("Completed rewards") {
                    RewardSummaryRow(label: "Earned", value: "\(store.money(store.completedDollars)) + \(store.pointsText) pts")
                    RewardSummaryRow(label: "Spend", value: store.money(store.spendDollars))
                    RewardSummaryRow(label: "Save", value: store.money(store.saveDollars))
                    RewardSummaryRow(label: "Give", value: store.money(store.giveDollars))
                }

                Section {
                    ShareLink(item: store.exportURL) {
                        Label("Share or save CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(!store.hasValidSplit)

                    Button("Start over", role: .destructive) {
                        isShowingResetConfirmation = true
                    }
                } footer: {
                    Text("Private by default: chore names and progress stay on this device and are never sent to Dino Chat or Azure.")
                }
            }
            .navigationTitle("Chore Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Start a blank chore plan?", isPresented: $isShowingResetConfirmation, titleVisibility: .visible) {
                Button("Start Over", role: .destructive) { store.reset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This replaces the current plan on this device.")
            }
        }
    }
}

private struct TemplateLabel: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
                .frame(width: 42, height: 42)
                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
    }
}

private struct ChoreEditorRow: View {
    @Binding var chore: ChorePlanItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $chore.isComplete) {
                TextField("Chore name", text: $chore.title)
                    .font(.headline)
                    .strikethrough(chore.isComplete)
            }
            .tint(Color(red: 0.04, green: 0.55, blue: 0.39))

            HStack {
                TextField("Reward", value: $chore.value, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 120)

                Picker("Reward type", selection: $chore.kind) {
                    ForEach(ChoreRewardKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SplitStepper: View {
    let title: String
    @Binding var value: Int
    let tint: Color

    var body: some View {
        Stepper(value: $value, in: 0...100, step: 5) {
            HStack {
                Circle().fill(tint).frame(width: 10, height: 10)
                Text(title)
                Spacer()
                Text("\(value)%").fontWeight(.bold).monospacedDigit()
            }
        }
    }
}

private struct RewardSummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.bold).monospacedDigit()
        }
    }
}

private enum ChoreRewardKind: String, Codable, CaseIterable, Identifiable {
    case dollars
    case points

    var id: String { rawValue }
    var title: String { self == .dollars ? "Dollars" : "Points" }
}

private struct ChorePlanItem: Identifiable, Codable {
    var id: UUID
    var title: String
    var value: Double
    var kind: ChoreRewardKind
    var isComplete: Bool

    init(title: String, value: Double, kind: ChoreRewardKind) {
        id = UUID()
        self.title = title
        self.value = value
        self.kind = kind
        isComplete = false
    }
}

private enum ChorePlanTemplate {
    case littleHelper
    case allowanceBuilder
    case schoolWeek
}

private struct ChorePlanSnapshot: Codable {
    let chores: [ChorePlanItem]
    let spendPercent: Int
    let savePercent: Int
    let givePercent: Int
}

@MainActor
private final class ChorePlannerStore: ObservableObject {
    @Published var chores: [ChorePlanItem] { didSet { save() } }
    @Published var spendPercent: Int { didSet { save() } }
    @Published var savePercent: Int { didSet { save() } }
    @Published var givePercent: Int { didSet { save() } }
    @Published private(set) var exportURL: URL

    private let storageKey = "moneymuncher.chorePlan.v1"
    private var isReadyToSave = false

    init() {
        exportURL = FileManager.default.temporaryDirectory.appendingPathComponent("moneymuncher-family-chore-plan.csv")

        if let data = UserDefaults.standard.data(forKey: storageKey),
           let snapshot = try? JSONDecoder().decode(ChorePlanSnapshot.self, from: data) {
            chores = snapshot.chores
            spendPercent = snapshot.spendPercent
            savePercent = snapshot.savePercent
            givePercent = snapshot.givePercent
        } else {
            chores = Self.allowanceBuilder
            spendPercent = 40
            savePercent = 50
            givePercent = 10
        }

        isReadyToSave = true
        save()
    }

    var completedCount: Int { chores.filter(\.isComplete).count }
    var completionProgress: Double { chores.isEmpty ? 0 : Double(completedCount) / Double(chores.count) }
    var splitTotal: Int { spendPercent + savePercent + givePercent }
    var hasValidSplit: Bool { splitTotal == 100 }

    var completedDollars: Double {
        chores.filter { $0.isComplete && $0.kind == .dollars }.reduce(0) { $0 + max(0, $1.value) }
    }

    var completedPoints: Double {
        chores.filter { $0.isComplete && $0.kind == .points }.reduce(0) { $0 + max(0, $1.value) }
    }

    var pointsText: String {
        completedPoints.formatted(.number.precision(.fractionLength(0...2)))
    }

    var spendDollars: Double { completedDollars * Double(spendPercent) / 100 }
    var saveDollars: Double { completedDollars * Double(savePercent) / 100 }
    var giveDollars: Double { completedDollars * Double(givePercent) / 100 }

    func money(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    func addChore() {
        chores.append(ChorePlanItem(title: "New chore", value: 1, kind: .points))
    }

    func deleteChores(at offsets: IndexSet) {
        chores.remove(atOffsets: offsets)
    }

    func loadTemplate(_ template: ChorePlanTemplate) {
        switch template {
        case .littleHelper:
            chores = Self.littleHelper
            spendPercent = 40
            savePercent = 50
            givePercent = 10
        case .allowanceBuilder:
            chores = Self.allowanceBuilder
            spendPercent = 40
            savePercent = 50
            givePercent = 10
        case .schoolWeek:
            chores = Self.schoolWeek
            spendPercent = 30
            savePercent = 60
            givePercent = 10
        }
    }

    func reset() {
        chores = []
        spendPercent = 40
        savePercent = 50
        givePercent = 10
    }

    private func save() {
        guard isReadyToSave else { return }
        let snapshot = ChorePlanSnapshot(
            chores: chores,
            spendPercent: spendPercent,
            savePercent: savePercent,
            givePercent: givePercent
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        try? csvText().write(to: exportURL, atomically: true, encoding: .utf8)
    }

    private func csvText() -> String {
        let rows: [[String]] = [
            ["MoneyMuncher Family Chore Plan"],
            ["Chore", "Status", "Reward", "Unit"]
        ] + chores.map { chore in
            [chore.title, chore.isComplete ? "Complete" : "Not complete", String(chore.value), chore.kind.rawValue]
        } + [
            [],
            ["Completed dollars", String(completedDollars)],
            ["Completed points", String(completedPoints)],
            ["Spend percentage", "\(spendPercent)%", "Spend amount", money(spendDollars)],
            ["Save percentage", "\(savePercent)%", "Save amount", money(saveDollars)],
            ["Give percentage", "\(givePercent)%", "Give amount", money(giveDollars)]
        ]

        return "\u{FEFF}" + rows.map { $0.map(csvCell).joined(separator: ",") }.joined(separator: "\r\n")
    }

    private func csvCell(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static var littleHelper: [ChorePlanItem] {
        [
            ChorePlanItem(title: "Make the bed", value: 2, kind: .points),
            ChorePlanItem(title: "Put toys and books away", value: 3, kind: .points),
            ChorePlanItem(title: "Help clear the table", value: 2, kind: .points),
            ChorePlanItem(title: "Match clean socks", value: 3, kind: .points)
        ]
    }

    private static var allowanceBuilder: [ChorePlanItem] {
        [
            ChorePlanItem(title: "Load or unload the dishwasher", value: 1.5, kind: .dollars),
            ChorePlanItem(title: "Fold and put away laundry", value: 2, kind: .dollars),
            ChorePlanItem(title: "Tidy the bedroom", value: 1.5, kind: .dollars),
            ChorePlanItem(title: "Help with a family meal", value: 2, kind: .dollars)
        ]
    }

    private static var schoolWeek: [ChorePlanItem] {
        [
            ChorePlanItem(title: "Pack the school bag", value: 2, kind: .points),
            ChorePlanItem(title: "Put lunch items by the sink", value: 1, kind: .points),
            ChorePlanItem(title: "Finish the homework check", value: 3, kind: .points),
            ChorePlanItem(title: "Prepare clothes for tomorrow", value: 2, kind: .points)
        ]
    }
}
