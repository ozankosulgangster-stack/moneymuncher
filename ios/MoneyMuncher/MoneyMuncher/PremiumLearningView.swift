import SwiftUI

struct PremiumLearningHubView: View {
    @Environment(\.dismiss) private var dismiss

    private let modules = PremiumLearningModule.dinoModules

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hubHeader

                    ForEach(modules) { module in
                        NavigationLink(value: module) {
                            PremiumLearningModuleCard(module: module)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Learning only. Money Muncher uses virtual examples, not real-money trading advice.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Dino Money Lab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(for: PremiumLearningModule.self) { module in
                PremiumLearningModuleDetailView(module: module)
            }
        }
    }

    private var hubHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            DinoAvatar(size: 72)

            VStack(alignment: .leading, spacing: 8) {
                Text("Dino Money Lab")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.05, green: 0.26, blue: 0.23))

                Text("Short Plus lessons about cards, interest, and investing basics.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.98, blue: 0.83),
                    Color(red: 0.76, green: 0.92, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct PremiumLearningModuleCard: View {
    let module: PremiumLearningModule

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: module.systemImage)
                .font(.title2.weight(.bold))
                .frame(width: 46, height: 46)
                .foregroundStyle(Color(red: 0.05, green: 0.46, blue: 0.39))
                .background(Color(red: 0.88, green: 0.96, blue: 0.89))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(module.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(module.concept)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(Color(red: 0.04, green: 0.35, blue: 0.30))
                        .background(Color(red: 0.93, green: 0.97, blue: 0.88))
                        .clipShape(Capsule())
                }

                Text(module.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 10)

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct PremiumLearningModuleDetailView: View {
    let module: PremiumLearningModule

    @State private var selectedStepIndex = 0
    @State private var selectedAnswerIndex: Int?

    private var selectedStep: PremiumLessonStep {
        module.steps[selectedStepIndex]
    }

    private var isLastStep: Bool {
        selectedStepIndex == module.steps.count - 1
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                detailHeader
                stepProgress
                stepCard
                stepControls

                if isLastStep {
                    quizCard
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var detailHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            DinoAvatar(size: 68)

            VStack(alignment: .leading, spacing: 8) {
                Text(module.title)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.05, green: 0.26, blue: 0.23))

                Text(module.dinoLine)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var stepProgress: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(selectedStepIndex + 1) of \(module.steps.count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(uiColor: .tertiarySystemFill))

                    Capsule()
                        .fill(Color(red: 0.05, green: 0.46, blue: 0.39))
                        .frame(width: proxy.size.width * progressValue)
                }
            }
            .frame(height: 8)
        }
    }

    private var progressValue: CGFloat {
        CGFloat(selectedStepIndex + 1) / CGFloat(module.steps.count)
    }

    private var stepCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(selectedStep.title, systemImage: module.systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color(red: 0.05, green: 0.26, blue: 0.23))

            Text(selectedStep.body)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 10) {
                DinoAvatar(size: 42)

                Text(selectedStep.dinoTip)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.04, green: 0.35, blue: 0.30))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.93, green: 0.97, blue: 0.88))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var stepControls: some View {
        HStack(spacing: 12) {
            Button {
                selectedStepIndex = max(0, selectedStepIndex - 1)
                selectedAnswerIndex = nil
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(selectedStepIndex == 0)

            Button {
                selectedStepIndex = min(module.steps.count - 1, selectedStepIndex + 1)
                selectedAnswerIndex = nil
            } label: {
                Label("Next", systemImage: "chevron.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(isLastStep)
        }
    }

    private var quizCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Dino Check")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color(red: 0.05, green: 0.26, blue: 0.23))

            Text(module.quiz.prompt)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(module.quiz.answers.indices, id: \.self) { index in
                Button {
                    selectedAnswerIndex = index
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: answerIcon(for: index))
                            .foregroundStyle(answerColor(for: index))

                        Text(module.quiz.answers[index])
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(answerBackground(for: index))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if let selectedAnswerIndex {
                Text(selectedAnswerIndex == module.quiz.correctAnswerIndex ? "Correct. \(module.quiz.explanation)" : "Not quite. \(module.quiz.explanation)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(selectedAnswerIndex == module.quiz.correctAnswerIndex ? Color(red: 0.04, green: 0.35, blue: 0.30) : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func answerIcon(for index: Int) -> String {
        guard let selectedAnswerIndex else {
            return "circle"
        }

        if index == module.quiz.correctAnswerIndex {
            return "checkmark.circle.fill"
        }

        if index == selectedAnswerIndex {
            return "xmark.circle.fill"
        }

        return "circle"
    }

    private func answerColor(for index: Int) -> Color {
        guard selectedAnswerIndex != nil else {
            return Color(uiColor: .tertiaryLabel)
        }

        if index == module.quiz.correctAnswerIndex {
            return Color(red: 0.05, green: 0.46, blue: 0.39)
        }

        if index == selectedAnswerIndex {
            return .red
        }

        return Color(uiColor: .tertiaryLabel)
    }

    private func answerBackground(for index: Int) -> Color {
        guard selectedAnswerIndex != nil else {
            return Color(uiColor: .tertiarySystemGroupedBackground)
        }

        if index == module.quiz.correctAnswerIndex {
            return Color(red: 0.88, green: 0.96, blue: 0.89)
        }

        if index == selectedAnswerIndex {
            return Color(red: 1.0, green: 0.91, blue: 0.90)
        }

        return Color(uiColor: .tertiarySystemGroupedBackground)
    }
}

struct DinoAvatar: View {
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(Color(red: 0.18, green: 0.62, blue: 0.38))

            Circle()
                .fill(Color(red: 0.72, green: 0.92, blue: 0.64))
                .frame(width: size * 0.42, height: size * 0.42)
                .offset(x: size * 0.16, y: size * 0.16)

            HStack(spacing: size * 0.12) {
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.18, height: size * 0.18)
                    .overlay(
                        Circle()
                            .fill(Color(red: 0.05, green: 0.20, blue: 0.17))
                            .frame(width: size * 0.08, height: size * 0.08)
                    )

                Circle()
                    .fill(.white)
                    .frame(width: size * 0.18, height: size * 0.18)
                    .overlay(
                        Circle()
                            .fill(Color(red: 0.05, green: 0.20, blue: 0.17))
                            .frame(width: size * 0.08, height: size * 0.08)
                    )
            }
            .offset(x: -size * 0.05, y: -size * 0.10)

            HStack(spacing: size * 0.04) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: size * 0.02, style: .continuous)
                        .fill(.white)
                        .frame(width: size * 0.08, height: size * 0.10)
                }
            }
            .offset(x: size * 0.08, y: size * 0.26)

            Circle()
                .fill(Color(red: 0.11, green: 0.42, blue: 0.30))
                .frame(width: size * 0.10, height: size * 0.10)
                .offset(x: size * 0.28, y: size * 0.04)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
