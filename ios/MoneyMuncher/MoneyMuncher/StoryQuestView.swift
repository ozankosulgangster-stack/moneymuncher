import SwiftUI

struct StoryQuestView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("completedStoryQuests") private var completedStoryQuests = 0

    @State private var scene: WorldScene = .map
    @State private var completedStops: Set<WorldStop> = []
    @State private var selectedAnswer: Int?
    @State private var hasRecordedCompletion = false

    var body: some View {
        NavigationStack {
            ZStack {
                CardWorldPalette.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    worldHeader

                    ScrollView {
                        VStack(spacing: 20) {
                            worldProgress
                            sceneContent
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 36)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .interactiveDismissDisabled(scene != .map && scene != .ending)
    }

    private var worldHeader: some View {
        HStack {
            Button {
                if scene == .map || scene == .ending {
                    dismiss()
                } else {
                    selectedAnswer = nil
                    withAnimation(.easeInOut(duration: 0.25)) { scene = .map }
                }
            } label: {
                Image(systemName: scene == .map || scene == .ending ? "xmark" : "map.fill")
                    .font(.headline.weight(.bold))
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.9))
                    .clipShape(Circle())
            }
            .foregroundStyle(CardWorldPalette.ink)
            .accessibilityLabel(scene == .map || scene == .ending ? "Close Card Quest World" : "Back to world map")

            Spacer()

            VStack(spacing: 2) {
                Text("CARD QUEST WORLD")
                    .font(.caption.weight(.black))
                    .tracking(1.4)
                Text(scene.title)
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(CardWorldPalette.ink)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(CardWorldPalette.gold)
                Text("\(completedStops.count)/3")
                    .font(.headline.monospacedDigit().weight(.black))
            }
            .frame(minWidth: 58)
            .padding(.horizontal, 10)
            .frame(height: 42)
            .background(.white.opacity(0.9))
            .clipShape(Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(completedStops.count) of 3 story stars collected")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var worldProgress: some View {
        HStack(spacing: 8) {
            ForEach(WorldStop.allCases) { stop in
                Capsule()
                    .fill(completedStops.contains(stop) ? stop.color : CardWorldPalette.ink.opacity(0.12))
                    .frame(height: 7)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var sceneContent: some View {
        switch scene {
        case .map:
            mapScene
        case .loyalty:
            loyaltyScene
        case .credit:
            creditScene
        case .interest:
            interestScene
        case .ending:
            endingScene
        }
    }

    private var mapScene: some View {
        VStack(spacing: 18) {
            WorldBanner(
                eyebrow: completedStops.isEmpty ? "A NEW STORY ADVENTURE" : "KEEP EXPLORING",
                title: completedStops.count == 3 ? "The Moon Bank is glowing!" : "Three mysteries. Three story stars.",
                subtitle: completedStops.count == 3
                    ? "You learned what points, borrowing, and interest really mean."
                    : "Travel with Munch through a playful world of cards and coins.",
                emoji: completedStops.count == 3 ? "🌙" : "🦖",
                colors: [CardWorldPalette.sky, CardWorldPalette.mint]
            )

            if completedStops.isEmpty {
                CharacterBubble(
                    speaker: "MUNCH",
                    emoji: "🦖",
                    text: "A shiny card can unlock points—or a promise to pay later. Let's meet three guides who can tell the difference!"
                )
            }

            VStack(spacing: 14) {
                ForEach(WorldStop.allCases) { stop in
                    WorldStopCard(
                        stop: stop,
                        isComplete: completedStops.contains(stop),
                        isLocked: !isUnlocked(stop)
                    ) {
                        selectedAnswer = nil
                        withAnimation(.easeInOut(duration: 0.28)) {
                            scene = stop.scene
                        }
                    }
                }
            }

            if completedStops.count == 3 {
                QuestButton(title: "Enter the Moon Bank", systemImage: "sparkles") {
                    recordCompletion()
                    withAnimation(.easeInOut(duration: 0.3)) { scene = .ending }
                }
            } else {
                Text("Finish each chapter to open the next path. No real cards or personal information are used.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
            }
        }
    }

    private var loyaltyScene: some View {
        LessonScene(
            stop: .loyalty,
            character: "LUMA FOX",
            characterEmoji: "🦊",
            story: "At Star Market, Luma stamps a loyalty card when Munch shops. Ten stamps earn a free berry bowl—but a shop across the path sells the same berries for 4 fewer coins.",
            factTitle: "A loyalty card is a rewards tracker",
            factText: "It may give points, stamps, or discounts. It does not borrow money. Compare the real price, and ask a grown-up what information the program collects.",
            question: "What should Munch compare first?",
            answers: [
                LessonAnswer(title: "The final price", subtitle: "Check what the berries cost after any reward", isCorrect: true),
                LessonAnswer(title: "The shiniest card", subtitle: "A fancy design does not make a better deal", isCorrect: false),
                LessonAnswer(title: "Points only", subtitle: "Points can hide a higher price", isCorrect: false)
            ]
        )
    }

    private var creditScene: some View {
        LessonScene(
            stop: .credit,
            character: "CAPTAIN CREDIT",
            characterEmoji: "🦉",
            story: "At Cloud Castle, Captain Credit lends Munch 30 coins for a kite. The card works now, but a bill arrives later. Those 30 coins were borrowed—not a gift.",
            factTitle: "A credit card is a borrowing tool",
            factText: "The bank pays the shop, then the cardholder must repay the bank. A credit limit is the most that can be borrowed, not extra money to spend.",
            question: "The 30-coin bill is due Friday. What is the safest plan?",
            answers: [
                LessonAnswer(title: "Pay all 30 on time", subtitle: "That avoids carrying the balance forward", isCorrect: true),
                LessonAnswer(title: "Forget the bill", subtitle: "Late payments can add costs", isCorrect: false),
                LessonAnswer(title: "Borrow 30 more", subtitle: "New borrowing does not erase the first bill", isCorrect: false)
            ]
        )
    }

    private var interestScene: some View {
        LessonScene(
            stop: .interest,
            character: "PROFESSOR PERCENT",
            characterEmoji: "🐢",
            story: "On Percent Peak, a 100-coin balance waits for one year. The sign says 20% yearly interest. Professor Percent shows Munch that 20% of 100 is 20.",
            factTitle: "Interest is a price or a reward",
            factText: "When money is borrowed, interest is the extra cost. When money is saved, interest can help it grow. The rate tells how quickly that amount changes.",
            question: "If nothing is paid, what could the 100-coin balance become after one year?",
            answers: [
                LessonAnswer(title: "120 coins", subtitle: "100 borrowed + 20 interest", isCorrect: true),
                LessonAnswer(title: "100 coins", subtitle: "That leaves out the interest", isCorrect: false),
                LessonAnswer(title: "20 coins", subtitle: "That is only the interest amount", isCorrect: false)
            ]
        )
    }

    private func LessonScene(
        stop: WorldStop,
        character: String,
        characterEmoji: String,
        story: String,
        factTitle: String,
        factText: String,
        question: String,
        answers: [LessonAnswer]
    ) -> some View {
        VStack(spacing: 18) {
            WorldBanner(
                eyebrow: stop.eyebrow,
                title: stop.name,
                subtitle: stop.subtitle,
                emoji: stop.emoji,
                colors: stop.gradient
            )

            CharacterBubble(speaker: character, emoji: characterEmoji, text: story)

            FactCard(title: factTitle, text: factText, color: stop.color)

            VStack(alignment: .leading, spacing: 12) {
                Text("STORY CHOICE")
                    .font(.caption.weight(.black))
                    .tracking(1.1)
                    .foregroundStyle(stop.color)

                Text(question)
                    .font(.title3.weight(.black))
                    .foregroundStyle(CardWorldPalette.ink)

                ForEach(Array(answers.enumerated()), id: \.offset) { index, answer in
                    LessonChoiceButton(
                        answer: answer,
                        isSelected: selectedAnswer == index,
                        hasAnswered: selectedAnswer != nil,
                        tint: stop.color
                    ) {
                        guard selectedAnswer == nil else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            selectedAnswer = index
                        }
                    }
                }
            }
            .questCard()

            if let selectedAnswer {
                let answer = answers[selectedAnswer]

                FeedbackCard(
                    isCorrect: answer.isCorrect,
                    text: answer.isCorrect
                        ? stop.correctMessage
                        : "Good try. \(stop.tryAgainMessage)"
                )

                QuestButton(title: "Collect the story star", systemImage: "star.fill") {
                    complete(stop)
                }
            }
        }
    }

    private var endingScene: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(CardWorldPalette.gold.opacity(0.24))
                    .frame(width: 180, height: 180)

                Text("🏦")
                    .font(.system(size: 92))
            }
            .padding(.top, 14)

            VStack(spacing: 8) {
                Text("WORLD COMPLETE!")
                    .font(.caption.weight(.black))
                    .foregroundStyle(CardWorldPalette.green)
                    .tracking(1.5)

                Text("You're a Card-Smart Explorer")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(CardWorldPalette.ink)
                    .multilineTextAlignment(.center)

                Text("You can now spot the difference between earning rewards, borrowing money, and paying or earning interest.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                ResultStat(icon: "star.fill", value: "3 / 3", label: "Stories")
                ResultStat(icon: "checkmark.shield.fill", value: "Smart", label: "Card choices")
                ResultStat(icon: "percent", value: "20", label: "Math power")
            }

            VStack(alignment: .leading, spacing: 12) {
                TakeawayRow(emoji: "⭐️", text: "Loyalty cards track rewards—compare the final price.")
                TakeawayRow(emoji: "💳", text: "Credit cards borrow money that must be repaid.")
                TakeawayRow(emoji: "%", text: "Interest can cost borrowers or reward savers.")
            }
            .questCard()

            QuestButton(title: "Explore again", systemImage: "arrow.counterclockwise") {
                restart()
            }

            Button("Back to Money Muncher") { dismiss() }
                .font(.headline)
                .foregroundStyle(CardWorldPalette.green)

            if completedStoryQuests > 1 {
                Text("\(completedStoryQuests) Card Quest adventures completed")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func isUnlocked(_ stop: WorldStop) -> Bool {
        switch stop {
        case .loyalty:
            return true
        case .credit:
            return completedStops.contains(.loyalty)
        case .interest:
            return completedStops.contains(.credit)
        }
    }

    private func complete(_ stop: WorldStop) {
        completedStops.insert(stop)
        selectedAnswer = nil
        withAnimation(.easeInOut(duration: 0.3)) { scene = .map }
    }

    private func recordCompletion() {
        guard !hasRecordedCompletion else { return }
        completedStoryQuests += 1
        hasRecordedCompletion = true
    }

    private func restart() {
        completedStops = []
        selectedAnswer = nil
        hasRecordedCompletion = false
        withAnimation(.easeInOut(duration: 0.3)) { scene = .map }
    }
}

private enum WorldScene {
    case map
    case loyalty
    case credit
    case interest
    case ending

    var title: String {
        switch self {
        case .map: return "World map"
        case .loyalty: return "Star Market"
        case .credit: return "Cloud Castle"
        case .interest: return "Percent Peak"
        case .ending: return "Moon Bank"
        }
    }
}

private enum WorldStop: String, CaseIterable, Identifiable {
    case loyalty
    case credit
    case interest

    var id: String { rawValue }

    var scene: WorldScene {
        switch self {
        case .loyalty: return .loyalty
        case .credit: return .credit
        case .interest: return .interest
        }
    }

    var eyebrow: String {
        switch self {
        case .loyalty: return "CHAPTER 1 · REWARDS"
        case .credit: return "CHAPTER 2 · BORROWING"
        case .interest: return "CHAPTER 3 · RATES"
        }
    }

    var name: String {
        switch self {
        case .loyalty: return "Star Market"
        case .credit: return "Cloud Castle"
        case .interest: return "Percent Peak"
        }
    }

    var subtitle: String {
        switch self {
        case .loyalty: return "Luma Fox and the loyalty-card puzzle"
        case .credit: return "Captain Credit and the promise to repay"
        case .interest: return "Professor Percent and the growing balance"
        }
    }

    var emoji: String {
        switch self {
        case .loyalty: return "🛍️"
        case .credit: return "🏰"
        case .interest: return "⛰️"
        }
    }

    var color: Color {
        switch self {
        case .loyalty: return CardWorldPalette.purple
        case .credit: return CardWorldPalette.blue
        case .interest: return CardWorldPalette.orange
        }
    }

    var gradient: [Color] {
        switch self {
        case .loyalty: return [Color(red: 0.90, green: 0.78, blue: 0.97), Color(red: 1.00, green: 0.86, blue: 0.63)]
        case .credit: return [CardWorldPalette.sky, Color(red: 0.77, green: 0.73, blue: 0.98)]
        case .interest: return [Color(red: 1.00, green: 0.78, blue: 0.50), Color(red: 0.99, green: 0.91, blue: 0.62)]
        }
    }

    var correctMessage: String {
        switch self {
        case .loyalty: return "Exactly. A reward is useful only when the whole deal still makes sense."
        case .credit: return "That's the card-smart move. Paying the full bill on time avoids carrying this balance forward."
        case .interest: return "Right! Twenty percent of 100 is 20, so 100 + 20 becomes 120 coins."
        }
    }

    var tryAgainMessage: String {
        switch self {
        case .loyalty: return "Start with the final price; points are only one part of the deal."
        case .credit: return "Borrowed coins still belong on the bill, so paying the full amount on time is safest."
        case .interest: return "Add the 20-coin interest charge to the original 100-coin balance."
        }
    }
}

private struct LessonAnswer {
    let title: String
    let subtitle: String
    let isCorrect: Bool
}

private struct CardWorldPalette {
    static let background = Color(red: 0.95, green: 0.97, blue: 0.93)
    static let ink = Color(red: 0.08, green: 0.19, blue: 0.17)
    static let green = Color(red: 0.07, green: 0.47, blue: 0.34)
    static let mint = Color(red: 0.65, green: 0.90, blue: 0.75)
    static let sky = Color(red: 0.62, green: 0.84, blue: 0.96)
    static let gold = Color(red: 0.98, green: 0.74, blue: 0.18)
    static let orange = Color(red: 0.90, green: 0.42, blue: 0.12)
    static let blue = Color(red: 0.13, green: 0.45, blue: 0.74)
    static let purple = Color(red: 0.48, green: 0.28, blue: 0.70)
}

private struct WorldBanner: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let emoji: String
    let colors: [Color]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)

            Circle()
                .fill(.white.opacity(0.25))
                .frame(width: 180, height: 180)
                .offset(x: 235, y: -75)

            Text(emoji)
                .font(.system(size: 88))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 22)
                .padding(.bottom, 32)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 5)

            VStack(alignment: .leading, spacing: 7) {
                Text(eyebrow)
                    .font(.caption.weight(.black))
                    .tracking(1.1)
                Text(title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .frame(maxWidth: 255, alignment: .leading)
                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: 270, alignment: .leading)
            }
            .foregroundStyle(CardWorldPalette.ink)
            .padding(22)
        }
        .frame(height: 235)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct CharacterBubble: View {
    let speaker: String
    let emoji: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.system(size: 38))
                .frame(width: 54, height: 54)
                .background(CardWorldPalette.mint.opacity(0.34))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(speaker)
                    .font(.caption.weight(.black))
                    .foregroundStyle(CardWorldPalette.green)
                    .tracking(1)
                Text(text)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(CardWorldPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .questCard()
    }
}

private struct WorldStopCard: View {
    let stop: WorldStop
    let isComplete: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(stop.emoji)
                    .font(.system(size: 38))
                    .frame(width: 62, height: 62)
                    .background(stop.color.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(stop.eyebrow)
                        .font(.caption2.weight(.black))
                        .tracking(0.8)
                        .foregroundStyle(stop.color)
                    Text(stop.name)
                        .font(.headline)
                        .foregroundStyle(CardWorldPalette.ink)
                    Text(stop.subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: isComplete ? "checkmark.circle.fill" : isLocked ? "lock.fill" : "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isComplete ? CardWorldPalette.green : isLocked ? .gray : stop.color)
            }
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            .opacity(isLocked ? 0.62 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .accessibilityHint(isLocked ? "Finish the previous story to unlock" : isComplete ? "Replay this story" : "Start this story")
    }
}

private struct FactCard: View {
    let title: String
    let text: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("MONEY MAGIC REVEALED", systemImage: "lightbulb.fill")
                .font(.caption.weight(.black))
                .tracking(1)
                .foregroundStyle(color)
            Text(title)
                .font(.title3.weight(.black))
                .foregroundStyle(CardWorldPalette.ink)
            Text(text)
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .questCard()
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 5)
                .padding(.vertical, 16)
        }
    }
}

private struct LessonChoiceButton: View {
    let answer: LessonAnswer
    let isSelected: Bool
    let hasAnswered: Bool
    let tint: Color
    let action: () -> Void

    private var stateColor: Color {
        guard hasAnswered else { return tint }
        if answer.isCorrect { return CardWorldPalette.green }
        return isSelected ? CardWorldPalette.orange : .gray
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: hasAnswered && answer.isCorrect ? "checkmark.circle.fill" : isSelected ? "xmark.circle.fill" : "circle")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(stateColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(answer.title)
                        .font(.headline)
                        .foregroundStyle(CardWorldPalette.ink)
                    Text(answer.subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(stateColor.opacity(hasAnswered ? 0.12 : 0.07))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(hasAnswered && (isSelected || answer.isCorrect) ? stateColor : .clear, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(hasAnswered)
    }
}

private struct FeedbackCard: View {
    let isCorrect: Bool
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isCorrect ? "sparkles" : "arrow.triangle.2.circlepath")
                .font(.title2.weight(.bold))
                .foregroundStyle(isCorrect ? CardWorldPalette.green : CardWorldPalette.orange)
            Text(text)
                .font(.body.weight(.bold))
                .foregroundStyle(CardWorldPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isCorrect ? CardWorldPalette.green : CardWorldPalette.orange).opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct TakeawayRow: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(emoji).font(.title3)
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(CardWorldPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ResultStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(CardWorldPalette.gold)
            Text(value)
                .font(.headline.monospacedDigit().weight(.black))
                .foregroundStyle(CardWorldPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct QuestButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: systemImage)
            }
            .font(.headline.weight(.bold))
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(.white)
            .background(CardWorldPalette.green)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private extension View {
    func questCard() -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
