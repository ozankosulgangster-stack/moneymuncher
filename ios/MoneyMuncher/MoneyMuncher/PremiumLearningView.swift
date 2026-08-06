import SwiftUI

struct PremiumLearningHubView: View {
    @Environment(\.dismiss) private var dismiss

    private let modules = PremiumLearningModule.dinoModules

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hubHeader

                    NavigationLink {
                        DinoStoryPlayerView()
                    } label: {
                        DinoStoryPreview()
                    }
                    .buttonStyle(.plain)

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

private struct DinoStoryPreview: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("DinoStoryBackdrop")
                .resizable()
                .scaledToFill()

            Color.black.opacity(0.24)

            HStack(alignment: .bottom, spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Dino's Money Story")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text("A narrated adventure about debit, interest, and saving.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Play Dino's Money Story")
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

    @StateObject private var narrator = LessonNarrator()
    @State private var selectedStepIndex = 0
    @State private var selectedAnswerIndex: Int?

    private var selectedStep: PremiumLessonStep {
        module.steps[selectedStepIndex]
    }

    private var isLastStep: Bool {
        selectedStepIndex == module.steps.count - 1
    }

    private var isNarratingCurrentStep: Bool {
        narrator.isSpeaking && narrator.spokenStepID == selectedStep.id
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
        .onDisappear {
            narrator.stop()
        }
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

            lessonAudioControls

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

    private var lessonAudioControls: some View {
        HStack(spacing: 10) {
            Button {
                toggleNarration()
            } label: {
                Label(isNarratingCurrentStep ? "Stop Audio" : "Listen", systemImage: isNarratingCurrentStep ? "stop.fill" : "speaker.wave.2.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LessonNarrationButtonStyle(isActive: isNarratingCurrentStep))
            .accessibilityHint(isNarratingCurrentStep ? "Stops the lesson audio" : "Reads the current lesson step aloud")

            Button {
                speakCurrentStep()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.headline.weight(.bold))
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(LessonIconButtonStyle())
            .accessibilityLabel("Replay audio")
            .accessibilityHint("Starts the current lesson step again")
        }
    }

    private var stepControls: some View {
        HStack(spacing: 12) {
            Button {
                moveToStep(selectedStepIndex - 1)
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .disabled(selectedStepIndex == 0)

            Button {
                moveToStep(selectedStepIndex + 1)
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

    private func toggleNarration() {
        if isNarratingCurrentStep {
            narrator.stop()
        } else {
            speakCurrentStep()
        }
    }

    private func speakCurrentStep() {
        narrator.speak(module: module, step: selectedStep)
    }

    private func moveToStep(_ stepIndex: Int) {
        narrator.stop()
        selectedStepIndex = min(max(stepIndex, 0), module.steps.count - 1)
        selectedAnswerIndex = nil
    }
}

private struct DinoStoryScene: Identifiable {
    enum Visual {
        case debit
        case interest
        case saving
    }

    let id: String
    let narratorName: String
    let title: String
    let subtitle: String
    let narration: String
    let boardCaption: String
    let visual: Visual
    let recordingResource: String?

    var storyBackdropName: String? {
        switch visual {
        case .debit:
            return "DinoDebitStoryBackdrop"
        case .interest:
            return nil
        case .saving:
            return "DinoSavingStoryBackdrop"
        }
    }
}

private struct DinoStoryPlayerView: View {
    @StateObject private var narrator = LessonNarrator()
    @State private var selectedSceneIndex = 0
    @State private var isPlayingStory = false

    private let scenes: [DinoStoryScene] = [
        DinoStoryScene(
            id: "debit-story",
            narratorName: "Dino",
            title: "Mia's snack-shop choice",
            subtitle: "Debit uses money you have now.",
            narration: "Hi, I am Dino! Today I am helping my friend Mia use a debit card. Mia has twenty dollars in her bank account. That is her balance, like a money backpack. At the snack shop, she chooses a juice for three dollars and a fruit cup for two dollars. She checks that twenty dollars is enough, then taps her debit card. Five dollars comes out of her account right away, so Mia has fifteen dollars left. Next she sees a toy for eighteen dollars. It looks fun, but fifteen dollars is not enough. A debit card does not create extra money. Mia decides to save for the toy instead. Before you tap, swipe, or buy online, check your balance. Ask: do I have enough, and will I have money left for things I need? Check, choose, and spend smart!",
            boardCaption: "Check your balance before you tap.",
            visual: .debit,
            recordingResource: nil
        ),
        DinoStoryScene(
            id: "interest-story",
            narratorName: "Ollie Owl",
            title: "Two kinds of interest",
            subtitle: "Saving can earn; borrowing can cost.",
            narration: "Interest has two jobs. Savings can earn a little extra money over time. Borrowed money can cost extra when you pay it back later. That is why paying a credit card bill in full and on time matters.",
            boardCaption: "Saving earns. Borrowing costs.",
            visual: .interest,
            recordingResource: "ollie-interest"
        ),
        DinoStoryScene(
            id: "saving-story",
            narratorName: "Dino",
            title: "Leo's soccer-ball goal",
            subtitle: "Small saves build a goal.",
            narration: "Hi, I'm Dino! Today I'm helping my friend Leo save for something special. Leo wants a new soccer ball that costs thirty dollars. Right now, he has eight dollars in his savings jar. That means he needs twenty-two more dollars to reach his goal. Leo gets five dollars for helping wash the car. He could spend it on candy, but he remembers his soccer-ball goal. He puts four dollars into his savings jar and keeps one dollar for a small treat. Now Leo has twelve dollars saved. A week later, Leo receives ten dollars for his birthday. He puts six dollars into his jar. His family also finds four dollars of change from an old coat pocket. Leo adds that too. Let's count: eight dollars, plus four dollars, plus six dollars, plus four dollars. Leo now has twenty-two dollars saved! He is not at thirty dollars yet, but he is getting closer. Leo makes a plan: each week, he will save three dollars from his allowance. After a few more weeks, his jar will reach thirty dollars. Saving is not about never spending. It is about choosing what matters most and giving your money a job for later. Pick a goal. Write down how much it costs. Add small amounts often. Watch your savings grow. That's Dino-smart saving!",
            boardCaption: "Small amounts move a goal forward.",
            visual: .saving,
            recordingResource: "dino-saving"
        )
    ]

    private var currentScene: DinoStoryScene {
        scenes[selectedSceneIndex]
    }

    private var isLastScene: Bool {
        selectedSceneIndex == scenes.count - 1
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                storyStage
                storyProgress
                storyText
                storyControls
                scenePicker

                Text("Dino uses pretend money in this story. Talk through real money choices with a parent or guardian.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Dino's Money Story")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            stopStory()
        }
    }

    @ViewBuilder
    private var storyStage: some View {
        switch currentScene.visual {
        case .interest:
            OllieInterestStoryStage(
                speechLevel: narrator.speechLevel,
                playbackProgress: narrator.recordedPlaybackProgress,
                isNarrating: narrator.isSpeaking && narrator.spokenStepID == currentScene.id
            )

        case .debit, .saving:
            DinoTeacherStoryStage(
                scene: currentScene,
                isNarrating: narrator.isSpeaking && narrator.spokenStepID == currentScene.id,
                speechLevel: narrator.speechLevel,
                sceneNumber: selectedSceneIndex + 1
            )
        }
    }

    private var storyProgress: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Scene \(selectedSceneIndex + 1) of \(scenes.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(currentScene.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.04, green: 0.35, blue: 0.30))
                    .multilineTextAlignment(.trailing)
            }

            ProgressView(value: Double(selectedSceneIndex + 1), total: Double(scenes.count))
                .tint(Color(red: 0.05, green: 0.46, blue: 0.39))
        }
    }

    private var storyText: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Narrated by \(currentScene.narratorName)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(red: 0.04, green: 0.35, blue: 0.30))

            Text(currentScene.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color(red: 0.05, green: 0.26, blue: 0.23))

            Text(currentScene.narration)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var storyControls: some View {
        HStack(spacing: 12) {
            Button {
                isPlayingStory ? stopStory() : startStory()
            } label: {
                Label(isPlayingStory ? "Stop Story" : "Play Story", systemImage: isPlayingStory ? "stop.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle())

            Button {
                selectScene(min(selectedSceneIndex + 1, scenes.count - 1))
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.bold))
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(LessonIconButtonStyle())
            .disabled(isLastScene)
            .accessibilityLabel("Next story scene")
        }
    }

    private var scenePicker: some View {
        HStack(spacing: 8) {
            ForEach(scenes.indices, id: \.self) { index in
                let scene = scenes[index]

                Button {
                    selectScene(index)
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: icon(for: scene.visual))
                            .font(.headline.weight(.bold))

                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(index == selectedSceneIndex ? .white : Color(red: 0.04, green: 0.35, blue: 0.30))
                    .background(index == selectedSceneIndex ? Color(red: 0.04, green: 0.43, blue: 0.36) : Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Scene \(index + 1): \(scene.title)")
            }
        }
    }

    private func startStory() {
        narrator.stop()
        isPlayingStory = true
        playScene(at: 0, advancesStory: true)
    }

    private func playScene(at index: Int, advancesStory: Bool) {
        guard scenes.indices.contains(index) else {
            stopStory()
            return
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            selectedSceneIndex = index
        }

        narrateScene(scenes[index]) {
            guard advancesStory, isPlayingStory else {
                return
            }

            if index < scenes.count - 1 {
                playScene(at: index + 1, advancesStory: true)
            } else {
                stopStory()
            }
        }
    }

    private func selectScene(_ index: Int) {
        guard scenes.indices.contains(index) else {
            return
        }

        stopStory()
        withAnimation(.easeInOut(duration: 0.35)) {
            selectedSceneIndex = index
        }
        narrateScene(scenes[index])
    }

    private func stopStory() {
        isPlayingStory = false
        narrator.stop()
    }

    private func narrateScene(_ scene: DinoStoryScene, completion: (() -> Void)? = nil) {
        if let recordingResource = scene.recordingResource {
            narrator.playRecordedAudio(
                resource: recordingResource,
                id: scene.id,
                fallbackText: scene.narration,
                completion: completion
            )
        } else {
            narrator.speak(id: scene.id, text: scene.narration, completion: completion)
        }
    }

    private func icon(for visual: DinoStoryScene.Visual) -> String {
        switch visual {
        case .debit:
            return "creditcard.fill"
        case .interest:
            return "arrow.triangle.2.circlepath"
        case .saving:
            return "target"
        }
    }
}

private struct DinoTeacherStoryStage: View {
    let scene: DinoStoryScene
    let isNarrating: Bool
    let speechLevel: Float
    let sceneNumber: Int

    @State private var isTeachingMotion = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let storyBackdropName = scene.storyBackdropName {
                    Image(storyBackdropName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }

                DinoStoryBoardVisual(scene: scene, isPlaying: isNarrating)
                    .frame(width: proxy.size.width * 0.34, height: proxy.size.height * 0.40)
                    .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .position(x: proxy.size.width * 0.25, y: proxy.size.height * 0.25)
                    .id(scene.id)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .animation(.easeInOut(duration: 0.4), value: scene.id)

                Image("DinoTeacher")
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width * 0.43, height: proxy.size.height * 0.76)
                    .position(x: proxy.size.width * 0.24, y: proxy.size.height * 0.69)
                    .offset(y: isNarrating && isTeachingMotion ? -6 : 0)
                    .rotationEffect(.degrees(isNarrating ? (isTeachingMotion ? -1.2 : 1.2) : 0))
                    .scaleEffect(1 + CGFloat(speechLevel) * 0.025)
                    .animation(.easeInOut(duration: 1.0), value: isTeachingMotion)
                    .animation(.linear(duration: 0.07), value: speechLevel)

                stageChrome
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dino story scene \(sceneNumber): \(scene.title)")
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isTeachingMotion = true
            }
        }
    }

    private var stageChrome: some View {
        VStack {
            HStack {
                Text("DINO TEACHES")
                    .font(.caption2.weight(.heavy))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .foregroundStyle(Color(red: 0.04, green: 0.35, blue: 0.30))
                    .background(.white.opacity(0.88))
                    .clipShape(Capsule())

                Spacer()
            }

            Spacer()

            HStack {
                Spacer()

                if isNarrating {
                    Label("Playing", systemImage: "speaker.wave.2.fill")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .foregroundStyle(.white)
                        .background(.black.opacity(0.38))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
    }
}

private struct DinoStoryBoardVisual: View {
    let scene: DinoStoryScene
    let isPlaying: Bool

    var body: some View {
        VStack(spacing: 7) {
            Text(scene.title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.04, green: 0.29, blue: 0.25))

            HStack(spacing: 6) {
                visualIcons
            }
            .font(.system(size: 22, weight: .bold))

            Text(scene.boardCaption)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.13, green: 0.34, blue: 0.30))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .scaleEffect(isPlaying ? 1.03 : 1.0)
        .animation(
            isPlaying ? .easeInOut(duration: 1.1).repeatForever(autoreverses: true) : .default,
            value: isPlaying
        )
    }

    @ViewBuilder
    private var visualIcons: some View {
        switch scene.visual {
        case .debit:
            Image(systemName: "creditcard.fill")
                .foregroundStyle(Color(red: 0.04, green: 0.43, blue: 0.36))
            Image(systemName: "arrow.right")
                .foregroundStyle(Color(red: 0.13, green: 0.34, blue: 0.30))
            Image(systemName: "building.columns.fill")
                .foregroundStyle(Color(red: 0.10, green: 0.47, blue: 0.64))

        case .interest:
            Image(systemName: "banknote.fill")
                .foregroundStyle(Color(red: 0.04, green: 0.43, blue: 0.36))
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(Color(red: 0.80, green: 0.42, blue: 0.10))
            Image(systemName: "creditcard.fill")
                .foregroundStyle(Color(red: 0.57, green: 0.22, blue: 0.15))

        case .saving:
            Image(systemName: "coins.fill")
                .foregroundStyle(Color(red: 0.80, green: 0.55, blue: 0.08))
            Image(systemName: "arrow.right")
                .foregroundStyle(Color(red: 0.13, green: 0.34, blue: 0.30))
            Image(systemName: "target")
                .foregroundStyle(Color(red: 0.13, green: 0.42, blue: 0.68))
        }
    }
}

private struct OllieInterestStoryStage: View {
    enum StoryBeat {
        case saving
        case borrowing
        case payingInFull
    }

    let speechLevel: Float
    let playbackProgress: Double
    let isNarrating: Bool

    @State private var isFloating = false

    private var storyBeat: StoryBeat {
        if playbackProgress < 0.34 {
            return .saving
        }

        if playbackProgress < 0.70 {
            return .borrowing
        }

        return .payingInFull
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.89, green: 0.97, blue: 0.92),
                        Color(red: 0.73, green: 0.90, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                storyVisual(in: proxy.size)

                OllieTalkingAvatar(
                    speechLevel: speechLevel,
                    isNarrating: isNarrating
                )
                .frame(width: proxy.size.width * 0.49, height: proxy.size.height * 0.92)
                .position(x: proxy.size.width * 0.32, y: proxy.size.height * 0.56)
                .offset(y: isNarrating && isFloating ? -6 : 0)
                .rotationEffect(.degrees(isNarrating ? (isFloating ? -1.2 : 1.2) : 0))
                .animation(.easeInOut(duration: 1.15), value: isFloating)

                VStack {
                    HStack {
                        Text("OLLIE OWL NARRATES")
                            .font(.caption2.weight(.heavy))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .foregroundStyle(Color(red: 0.04, green: 0.35, blue: 0.30))
                            .background(.white.opacity(0.88))
                            .clipShape(Capsule())

                        Spacer()
                    }

                    Spacer()

                    HStack {
                        Spacer()

                        if isNarrating {
                            Label("Playing", systemImage: "speaker.wave.2.fill")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .foregroundStyle(.white)
                                .background(.black.opacity(0.38))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(14)
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ollie Owl explains saving and borrowing interest")
        .onAppear {
            startMotion()
        }
    }

    private func startMotion() {
        withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
            isFloating = true
        }
    }

    private func storyVisual(in size: CGSize) -> some View {
        InterestStoryBeatVisual(beat: storyBeat, isNarrating: isNarrating)
            .frame(width: size.width * 0.40, height: size.height * 0.50)
            .position(x: size.width * 0.75, y: size.height * 0.47)
            .id(storyBeat)
            .transition(.opacity.combined(with: .scale(scale: 0.92)))
            .animation(.easeInOut(duration: 0.35), value: playbackProgress)
    }
}

private struct InterestStoryBeatVisual: View {
    let beat: OllieInterestStoryStage.StoryBeat
    let isNarrating: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                beatIcon
                    .font(.system(size: 30, weight: .bold))

                Text(heading)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Color(red: 0.04, green: 0.29, blue: 0.25))

            Text(detail)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.13, green: 0.34, blue: 0.30))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .scaleEffect(isNarrating ? 1.03 : 1.0)
        .animation(
            isNarrating ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
            value: isNarrating
        )
    }

    private var heading: String {
        switch beat {
        case .saving:
            return "Savings can grow"
        case .borrowing:
            return "Borrowing can cost"
        case .payingInFull:
            return "Pay in full"
        }
    }

    private var detail: String {
        switch beat {
        case .saving:
            return "A bank may add a little extra over time."
        case .borrowing:
            return "Credit can cost extra to repay later."
        case .payingInFull:
            return "Paying on time helps avoid interest."
        }
    }

    @ViewBuilder
    private var beatIcon: some View {
        switch beat {
        case .saving:
            Image(systemName: "banknote.fill")
                .foregroundStyle(Color(red: 0.04, green: 0.43, blue: 0.36))
            Image(systemName: "arrow.up.right")
                .foregroundStyle(Color(red: 0.13, green: 0.42, blue: 0.68))

        case .borrowing:
            Image(systemName: "creditcard.fill")
                .foregroundStyle(Color(red: 0.57, green: 0.22, blue: 0.15))
            Image(systemName: "percent")
                .foregroundStyle(Color(red: 0.80, green: 0.42, blue: 0.10))

        case .payingInFull:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(red: 0.04, green: 0.43, blue: 0.36))
            Image(systemName: "calendar")
                .foregroundStyle(Color(red: 0.13, green: 0.42, blue: 0.68))
        }
    }
}

private struct OllieTalkingAvatar: View {
    let speechLevel: Float
    let isNarrating: Bool

    private let assetAspectRatio = 1112.0 / 1414.0

    var body: some View {
        GeometryReader { proxy in
            let imageHeight = min(proxy.size.height, proxy.size.width / assetAspectRatio)
            let imageWidth = imageHeight * assetAspectRatio
            let beakOffset = isNarrating ? imageHeight * (0.006 + CGFloat(speechLevel) * 0.022) : 0

            ZStack {
                Image("OllieOwl")
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageWidth, height: imageHeight)

                Image("OllieOwl")
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageWidth, height: imageHeight)
                    .mask {
                        Ellipse()
                            .frame(width: imageWidth * 0.17, height: imageHeight * 0.08)
                            .position(x: imageWidth * 0.505, y: imageHeight * 0.425)
                    }
                    .offset(y: beakOffset)
                    .animation(.linear(duration: 0.065), value: speechLevel)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityHidden(true)
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

private struct LessonNarrationButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .foregroundStyle(isActive ? Color(red: 0.04, green: 0.35, blue: 0.30) : .white)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isActive {
            return isPressed ? Color(red: 0.82, green: 0.93, blue: 0.88) : .white
        }

        return isPressed ? Color(red: 0.02, green: 0.30, blue: 0.25) : Color(red: 0.04, green: 0.43, blue: 0.36)
    }
}

private struct LessonIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(red: 0.04, green: 0.35, blue: 0.30))
            .background(configuration.isPressed ? Color(red: 0.82, green: 0.93, blue: 0.88) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
