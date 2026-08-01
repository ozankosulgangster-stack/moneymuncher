import AVFoundation
import Combine
import Foundation

final class LessonNarrator: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var isSpeaking = false
    @Published private(set) var spokenStepID: String?

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    deinit {
        stop()
    }

    func speak(module: PremiumLearningModule, step: PremiumLessonStep) {
        stop()
        prepareAudioSession()

        let lessonText = [
            module.title,
            step.title,
            step.body,
            step.dinoTip
        ].joined(separator: ". ")

        let utterance = AVSpeechUtterance(string: lessonText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.90
        utterance.pitchMultiplier = 1.08
        utterance.volume = 1.0

        isSpeaking = true
        spokenStepID = step.id
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }

        clearSpeechState()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.clearSpeechState()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.clearSpeechState()
        }
    }

    private func prepareAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            // Narration can still work without a configured session; keep the lesson flow moving.
        }
        #endif
    }

    private func clearSpeechState() {
        isSpeaking = false
        spokenStepID = nil
    }
}
