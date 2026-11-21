import AVFAudio
import os

final class SpeechAnnouncer: Announcing {
    private enum SpeechEvent: Sendable {
        case finished
        case cancelled
    }

    private final class SpeechDelegateProxy: NSObject, AVSpeechSynthesizerDelegate {
        let events: AsyncStream<SpeechEvent>
        private let continuation: AsyncStream<SpeechEvent>.Continuation

        override init() {
            (events, continuation) = AsyncStream.makeStream()
            super.init()
        }

        deinit {
            continuation.finish()
        }

        nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            continuation.yield(.finished)
        }

        nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
            continuation.yield(.cancelled)
        }
    }

    private static let logger = Logger(subsystem: "de.liehrit.planktrainer", category: "audio")

    private let audioSession: any AudioSessionControlling
    private let locale: Locale
    private let synthesizer = AVSpeechSynthesizer()
    private let delegateProxy = SpeechDelegateProxy()
    private var isSessionActive = false
    private var eventTask: Task<Void, Never>?

    init(audioSession: any AudioSessionControlling = AudioSessionController(), locale: Locale = AppLocale.current) {
        self.audioSession = audioSession
        self.locale = locale
        synthesizer.delegate = delegateProxy
        let events = delegateProxy.events
        eventTask = Task { [weak self] in
            for await _ in events {
                self?.handleSpeechEnded()
            }
        }
    }

    func prepare() throws(AnnouncerError) {
        do {
            try audioSession.configureForAnnouncements()
        } catch {
            Self.logger.error("Configuring audio session failed: \(error.localizedDescription)")
            throw .unavailable
        }
    }

    func speak(_ text: String) throws(AnnouncerError) {
        if !isSessionActive {
            do {
                try audioSession.activate()
            } catch {
                Self.logger.error("Activating audio session failed: \(error.localizedDescription)")
                throw .unavailable
            }
            isSessionActive = true
        }
        let utterance = AVSpeechUtterance(string: text)
        let appLanguage = locale.language.languageCode?.identifier ?? "en"
        utterance.voice = AVSpeechSynthesisVoice(
            language: Self.voiceLanguage(
                appLanguage: appLanguage,
                systemVoiceLanguage: AVSpeechSynthesisVoice.currentLanguageCode()
            )
        )
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    static func voiceLanguage(appLanguage: String, systemVoiceLanguage: String) -> String {
        systemVoiceLanguage.hasPrefix(appLanguage + "-") ? systemVoiceLanguage : appLanguage
    }

    private func handleSpeechEnded() {
        guard isSessionActive, !synthesizer.isSpeaking else { return }
        isSessionActive = false
        do {
            try audioSession.deactivate()
        } catch {
            Self.logger.error("Deactivating audio session failed: \(error.localizedDescription)")
        }
    }
}
