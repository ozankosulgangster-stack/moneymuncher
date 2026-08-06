import AVFoundation
import Combine
import Foundation

final class LessonNarrator: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    @Published private(set) var isSpeaking = false
    @Published private(set) var spokenStepID: String?
    @Published private(set) var speechLevel: Float = 0
    @Published private(set) var recordedPlaybackProgress: Double = 0

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var audioMeterTimer: Timer?
    private var synthesizerMeterTimer: Timer?
    private var synthesizerMeterPhase = 0
    private var onPlaybackFinished: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    deinit {
        stop()
    }

    func speak(module: PremiumLearningModule, step: PremiumLessonStep) {
        let lessonText = [
            module.title,
            step.title,
            step.body,
            step.dinoTip
        ].joined(separator: ". ")

        speak(id: step.id, text: lessonText)
    }

    func speak(id: String, text: String, completion: (() -> Void)? = nil) {
        stop()
        prepareAudioSession()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = thirdEnglishVoice()
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.90
        utterance.pitchMultiplier = 1.08
        utterance.volume = 1.0

        isSpeaking = true
        spokenStepID = id
        onPlaybackFinished = completion
        synthesizer.speak(utterance)
        startSynthesizerMetering()
    }

    func playRecordedAudio(resource: String, id: String, completion: (() -> Void)? = nil) {
        playRecordedAudio(resource: resource, id: id, fallbackText: nil, completion: completion)
    }

    func playRecordedAudio(resource: String, id: String, fallbackText: String?, completion: (() -> Void)? = nil) {
        stop()
        prepareAudioSession()

        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp3"),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            if let fallbackText {
                speak(id: id, text: fallbackText, completion: completion)
            } else {
                completion?()
            }
            return
        }

        player.delegate = self
        player.isMeteringEnabled = true
        player.prepareToPlay()

        audioPlayer = player
        isSpeaking = true
        spokenStepID = id
        recordedPlaybackProgress = 0
        onPlaybackFinished = completion

        if player.play() {
            startAudioMetering()
        } else {
            audioPlayer = nil
            finishPlayback()
        }
    }

    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }

        audioPlayer?.stop()
        audioPlayer = nil
        stopMeters()
        onPlaybackFinished = nil
        clearSpeechState()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.synthesizer.isSpeaking, self.audioPlayer == nil else {
                return
            }

            self.finishPlayback()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.startSynthesizerMetering()
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.speechLevel = 0.95
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.synthesizer.isSpeaking, self.audioPlayer == nil else {
                return
            }

            self.onPlaybackFinished = nil
            self.clearSpeechState()
            self.stopMeters()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.audioPlayer === player else {
                return
            }

            self.audioPlayer = nil
            self.finishPlayback()
        }
    }

    private func prepareAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers, .allowAirPlay, .allowBluetoothA2DP]
            )
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

    private func startAudioMetering() {
        stopMeters()

        let timer = Timer(timeInterval: 0.065, repeats: true) { [weak self] _ in
            self?.updateAudioMeter()
        }
        RunLoop.main.add(timer, forMode: .common)
        audioMeterTimer = timer
    }

    private func startSynthesizerMetering() {
        guard audioPlayer == nil else {
            return
        }

        synthesizerMeterTimer?.invalidate()
        synthesizerMeterPhase = 0

        let timer = Timer(timeInterval: 0.09, repeats: true) { [weak self] _ in
            guard let self, self.synthesizer.isSpeaking else {
                self?.synthesizerMeterTimer?.invalidate()
                self?.synthesizerMeterTimer = nil
                return
            }

            let levels: [Float] = [0.18, 0.78, 0.36, 0.92, 0.28, 0.62]
            self.speechLevel = levels[self.synthesizerMeterPhase % levels.count]
            self.synthesizerMeterPhase += 1
        }
        RunLoop.main.add(timer, forMode: .common)
        synthesizerMeterTimer = timer
    }

    private func stopMeters() {
        audioMeterTimer?.invalidate()
        audioMeterTimer = nil
        synthesizerMeterTimer?.invalidate()
        synthesizerMeterTimer = nil
        speechLevel = 0
        recordedPlaybackProgress = 0
    }

    private func updateAudioMeter() {
        guard let audioPlayer, audioPlayer.isPlaying else {
            speechLevel = 0
            return
        }

        audioPlayer.updateMeters()
        let decibels = audioPlayer.averagePower(forChannel: 0)
        let normalizedLevel = min(max((decibels + 42) / 42, 0), 1)
        speechLevel = (speechLevel * 0.30) + (normalizedLevel * 0.70)
        recordedPlaybackProgress = audioPlayer.duration > 0 ? audioPlayer.currentTime / audioPlayer.duration : 0
    }

    private func finishPlayback() {
        stopMeters()
        clearSpeechState()

        let completion = onPlaybackFinished
        onPlaybackFinished = nil
        completion?()
    }

    private func thirdEnglishVoice() -> AVSpeechSynthesisVoice? {
        let englishVoices = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.lowercased().hasPrefix("en")
        }

        return englishVoices.dropFirst(2).first ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}
