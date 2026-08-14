import StoreKit
import SwiftUI

struct MoneyMissionClipView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let invocationURL: URL?

    @State private var questionIndex = 0
    @State private var selectedChoice: Int?
    @State private var score = 0
    @State private var isFinished = false
    @State private var showAppStoreOverlay = false

    private let questions = MoneyMissionQuestion.all

    var body: some View {
        ZStack {
            ClipPalette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    clipHeader
                    animatedHero

                    if isFinished {
                        celebrationCard
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        missionCard
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }

                    privacyNote
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
        }
        .tint(ClipPalette.purple)
        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.82), value: questionIndex)
        .animation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.76), value: isFinished)
        .appStoreOverlay(isPresented: $showAppStoreOverlay) {
            SKOverlay.AppClipConfiguration(position: .bottom)
        }
    }

    private var clipHeader: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle().fill(ClipPalette.gold)
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(ClipPalette.ink)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 1) {
                Text("MONEY MUNCHER")
                    .font(.caption.weight(.black))
                    .tracking(1.2)
                    .foregroundStyle(ClipPalette.purple)
                Text("60-second money mission")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(ClipPalette.ink)
            }

            Spacer()

            Text(isFinished ? "DONE" : "\(questionIndex + 1)/\(questions.count)")
                .font(.caption.monospacedDigit().weight(.black))
                .foregroundStyle(ClipPalette.ink)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(.white.opacity(0.76), in: Capsule())
        }
    }

    private var animatedHero: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ClipPalette.purple, ClipPalette.deepPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(.white.opacity(0.10))
                    .frame(width: 168, height: 168)
                    .offset(x: 126, y: -64)

                VStack(alignment: .leading, spacing: 5) {
                    Text(invocationEyebrow)
                        .font(.caption.weight(.black))
                        .tracking(1.0)
                        .foregroundStyle(ClipPalette.gold)
                    Text("Make one smart\nmoney move.")
                        .font(.system(size: 31, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Choose, learn, and earn your first coin.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 22)
                .padding(.trailing, 108)

                Circle()
                    .fill(ClipPalette.mint.opacity(0.24))
                    .frame(width: 118, height: 118)
                    .offset(x: 116, y: 18)

                Image("ClipDino")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 106, height: 150)
                    .shadow(color: ClipPalette.deepPurple.opacity(0.28), radius: 9, y: 7)
                    .offset(x: 114, y: 19 + sin(time * 2.1) * 5)

                ForEach(0..<4, id: \.self) { index in
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: index.isMultiple(of: 2) ? 21 : 16, weight: .bold))
                        .foregroundStyle(ClipPalette.gold)
                        .rotationEffect(.degrees(time * (index.isMultiple(of: 2) ? 28 : -24)))
                        .offset(
                            x: 56 + CGFloat(index * 35),
                            y: -55 + CGFloat(index.isMultiple(of: 2) ? 0 : 29) + sin(time * 2.4 + Double(index)) * 6
                        )
                }
            }
            .frame(height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: ClipPalette.purple.opacity(0.24), radius: 18, y: 10)
        }
        .accessibilityHidden(true)
    }

    private var missionCard: some View {
        let question = questions[questionIndex]

        return VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 10) {
                Image(systemName: question.systemImage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(ClipPalette.purple)
                    .frame(width: 45, height: 45)
                    .background(ClipPalette.lavender, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(question.title)
                        .font(.title3.weight(.black))
                        .foregroundStyle(ClipPalette.ink)
                    Text("What would you do?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ClipPalette.muted)
                }
            }

            Text(question.prompt)
                .font(.body.weight(.semibold))
                .foregroundStyle(ClipPalette.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(question.choices.indices, id: \.self) { choiceIndex in
                    choiceButton(question: question, choiceIndex: choiceIndex)
                }
            }

            if let selectedChoice {
                feedback(for: question, selectedChoice: selectedChoice)

                Button(action: advance) {
                    HStack {
                        Text(questionIndex == questions.count - 1 ? "See My Result" : "Next Mission")
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 54)
                    .background(ClipPalette.purple, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: ClipPalette.ink.opacity(0.08), radius: 16, y: 7)
    }

    private func choiceButton(question: MoneyMissionQuestion, choiceIndex: Int) -> some View {
        let isSelected = selectedChoice == choiceIndex
        let isCorrect = choiceIndex == question.correctChoice
        let revealsCorrectChoice = selectedChoice != nil && isCorrect

        return Button {
            guard selectedChoice == nil else { return }
            selectedChoice = choiceIndex
            if isCorrect {
                score += 1
            }
        } label: {
            HStack(spacing: 12) {
                Text(question.choices[choiceIndex].emoji)
                    .font(.title2)
                Text(question.choices[choiceIndex].text)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ClipPalette.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 4)

                if isSelected || revealsCorrectChoice {
                    Image(systemName: revealsCorrectChoice ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(revealsCorrectChoice ? ClipPalette.green : ClipPalette.coral)
                        .font(.title3.weight(.bold))
                } else {
                    Circle()
                        .stroke(ClipPalette.purple.opacity(0.28), lineWidth: 2)
                        .frame(width: 21, height: 21)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                revealsCorrectChoice ? ClipPalette.mint.opacity(0.42) :
                    (isSelected ? ClipPalette.coral.opacity(0.13) : ClipPalette.lavender.opacity(0.46)),
                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(
                        revealsCorrectChoice ? ClipPalette.green.opacity(0.48) : ClipPalette.purple.opacity(0.10),
                        lineWidth: 1.5
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(selectedChoice != nil)
    }

    private func feedback(for question: MoneyMissionQuestion, selectedChoice: Int) -> some View {
        let isCorrect = selectedChoice == question.correctChoice

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: isCorrect ? "sparkles" : "lightbulb.fill")
                .foregroundStyle(isCorrect ? ClipPalette.green : ClipPalette.goldDark)
            Text(isCorrect ? "Smart move! \(question.explanation)" : question.explanation)
                .font(.footnote.weight(.bold))
                .foregroundStyle(ClipPalette.ink)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isCorrect ? ClipPalette.mint : ClipPalette.warmGold).opacity(0.48), in: RoundedRectangle(cornerRadius: 15))
        .accessibilityElement(children: .combine)
    }

    private var celebrationCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ClipPalette.gold.opacity(0.28))
                    .frame(width: 116, height: 116)
                Image(systemName: score == questions.count ? "trophy.fill" : "star.circle.fill")
                    .font(.system(size: 66, weight: .black))
                    .foregroundStyle(ClipPalette.goldDark)
                    .rotationEffect(.degrees(reduceMotion ? 0 : -4))
            }

            VStack(spacing: 6) {
                Text(score == questions.count ? "Money Mission Master!" : "Mission Complete!")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(ClipPalette.ink)
                    .multilineTextAlignment(.center)
                Text("You earned \(score) of \(questions.count) coins.")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(ClipPalette.purple)
            }

            Text("Keep playing with Cup Rush, family goals, shared activities, and character-led money lessons in the full app.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ClipPalette.muted)
                .multilineTextAlignment(.center)

            Button {
                showAppStoreOverlay = true
            } label: {
                Label("Get the Full Family Adventure", systemImage: "arrow.down.app.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(ClipPalette.purple, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            }
            .buttonStyle(.plain)

            Button("Play Again", action: restart)
                .font(.subheadline.weight(.bold))
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: ClipPalette.ink.opacity(0.08), radius: 16, y: 7)
    }

    private var privacyNote: some View {
        Label("No sign-in, purchase, or financial account is needed for this preview.", systemImage: "lock.shield.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(ClipPalette.muted)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    private var invocationEyebrow: String {
        guard let invocationURL,
              let components = URLComponents(url: invocationURL, resolvingAgainstBaseURL: false),
              let mission = components.queryItems?.first(where: { $0.name == "mission" })?.value else {
            return "QUICK FAMILY QUEST"
        }

        switch mission.lowercased() {
        case "gift": return "GIFT MONEY QUEST"
        case "save": return "SAVING QUEST"
        case "shop": return "SMART SHOPPING QUEST"
        default: return "QUICK FAMILY QUEST"
        }
    }

    private func advance() {
        if questionIndex == questions.count - 1 {
            isFinished = true
        } else {
            questionIndex += 1
            selectedChoice = nil
        }
    }

    private func restart() {
        questionIndex = 0
        selectedChoice = nil
        score = 0
        isFinished = false
    }
}

private struct MoneyMissionQuestion {
    struct Choice {
        let emoji: String
        let text: String
    }

    let title: String
    let prompt: String
    let systemImage: String
    let choices: [Choice]
    let correctChoice: Int
    let explanation: String

    static let all: [MoneyMissionQuestion] = [
        MoneyMissionQuestion(
            title: "The Bike Goal",
            prompt: "You have $20. A game costs $18, but you are also saving for a bike.",
            systemImage: "bicycle",
            choices: [
                Choice(emoji: "🎮", text: "Spend $18 right now"),
                Choice(emoji: "🚲", text: "Save $10 and plan the rest")
            ],
            correctChoice: 1,
            explanation: "Saving part first keeps your bike goal moving while leaving room for another choice."
        ),
        MoneyMissionQuestion(
            title: "Birthday Money",
            prompt: "You receive $15 for your birthday. What creates the most options later?",
            systemImage: "gift.fill",
            choices: [
                Choice(emoji: "🍭", text: "Spend every dollar today"),
                Choice(emoji: "🫙", text: "Save some and choose how to use the rest")
            ],
            correctChoice: 1,
            explanation: "A save-some plan lets you enjoy today and still prepare for something bigger."
        ),
        MoneyMissionQuestion(
            title: "Smart Shopping",
            prompt: "Your family is grocery shopping. Which move helps protect the budget?",
            systemImage: "cart.fill",
            choices: [
                Choice(emoji: "📝", text: "Use a list and compare prices"),
                Choice(emoji: "✨", text: "Buy every exciting extra")
            ],
            correctChoice: 0,
            explanation: "A list separates needs from extras, and comparing prices helps money go further."
        )
    ]
}

private enum ClipPalette {
    static let background = Color(red: 0.96, green: 0.94, blue: 1.00)
    static let lavender = Color(red: 0.91, green: 0.87, blue: 1.00)
    static let purple = Color(red: 0.42, green: 0.23, blue: 0.96)
    static let deepPurple = Color(red: 0.20, green: 0.11, blue: 0.43)
    static let ink = Color(red: 0.14, green: 0.09, blue: 0.28)
    static let muted = Color(red: 0.38, green: 0.33, blue: 0.51)
    static let gold = Color(red: 1.00, green: 0.84, blue: 0.30)
    static let goldDark = Color(red: 0.72, green: 0.48, blue: 0.02)
    static let warmGold = Color(red: 1.00, green: 0.93, blue: 0.69)
    static let mint = Color(red: 0.73, green: 0.96, blue: 0.85)
    static let green = Color(red: 0.05, green: 0.61, blue: 0.40)
    static let coral = Color(red: 0.95, green: 0.34, blue: 0.36)
}
