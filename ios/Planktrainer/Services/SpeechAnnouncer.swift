import AVFAudio
import os

final class SpeechAnnouncer: Announcing {
    private enum Command: Sendable {
        case speak(String)
        case stop
    }

    private static let logger = Logger(subsystem: "de.liehrit.planktrainer", category: "audio")

    private let audioSession: any AudioSessionControlling
    private let commands: AsyncStream<Command>.Continuation
    private(set) var isUnavailable = false

    init(audioSession: any AudioSessionControlling = AudioSessionController(), locale: Locale = AppLocale.current) {
        self.audioSession = audioSession
        let output = SpeechOutput(audioSession: audioSession, locale: locale)
        let (stream, continuation) = AsyncStream<Command>.makeStream()
        commands = continuation
        Task { [weak self] in
            for await command in stream {
                switch command {
                case .speak(let text):
                    let isAvailable = await output.speak(text)
                    self?.isUnavailable = !isAvailable
                case .stop:
                    await output.stop()
                }
            }
        }
    }

    deinit {
        commands.finish()
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
        commands.yield(.speak(text))
        if isUnavailable { throw .unavailable }
    }

    func stopSpeaking() {
        commands.yield(.stop)
    }

    nonisolated static func voiceLanguage(appLanguage: String, systemVoiceLanguage: String) -> String {
        systemVoiceLanguage.hasPrefix(appLanguage + "-") ? systemVoiceLanguage : appLanguage
    }
}

private nonisolated final class SpeechDelegateProxy: NSObject, AVSpeechSynthesizerDelegate {
    let events: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    override init() {
        (events, continuation) = AsyncStream.makeStream()
        super.init()
    }

    deinit {
        continuation.finish()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        continuation.yield()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        continuation.yield()
    }
}

/// Owns all blocking audio work on a dedicated serial queue so neither the main thread nor the cooperative pool stalls.
private actor SpeechOutput {
    private static let logger = Logger(subsystem: "de.liehrit.planktrainer", category: "audio")
    private static let deactivationAttempts = 5
    private static let deactivationRetryDelay = Duration.milliseconds(200)

    private let queue = DispatchSerialQueue(label: "de.liehrit.planktrainer.speech", qos: .userInitiated)
    private let audioSession: any AudioSessionControlling
    private let locale: Locale
    private let synthesizer = AVSpeechSynthesizer()
    private let delegateProxy = SpeechDelegateProxy()
    private var isSessionActive = false
    private lazy var voice = AVSpeechSynthesisVoice(
        language: SpeechAnnouncer.voiceLanguage(
            appLanguage: locale.language.languageCode?.identifier ?? "en",
            systemVoiceLanguage: AVSpeechSynthesisVoice.currentLanguageCode()
        )
    )

    nonisolated var unownedExecutor: UnownedSerialExecutor { queue.asUnownedSerialExecutor() }

    init(audioSession: any AudioSessionControlling, locale: Locale) {
        self.audioSession = audioSession
        self.locale = locale
        synthesizer.delegate = delegateProxy
        let events = delegateProxy.events
        Task { [weak self] in
            for await _ in events {
                await self?.handleSpeechEnded()
            }
        }
    }

    /// Returns whether the audio session could be activated and the utterance was handed to the synthesizer.
    func speak(_ text: String) -> Bool {
        if !isSessionActive {
            do {
                try audioSession.activate()
            } catch {
                Self.logger.error("Activating audio session failed: \(error.localizedDescription)")
                return false
            }
            isSessionActive = true
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        synthesizer.speak(utterance)
        return true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func handleSpeechEnded() async {
        for attempt in 1...Self.deactivationAttempts {
            guard isSessionActive, !synthesizer.isSpeaking else { return }
            do {
                try audioSession.deactivate()
                isSessionActive = false
                return
            } catch {
                Self.logger.error("Deactivating audio session failed (attempt \(attempt)): \(error.localizedDescription)")
            }
            guard attempt < Self.deactivationAttempts else { return }
            do {
                try await Task.sleep(for: Self.deactivationRetryDelay)
            } catch {
                return
            }
        }
    }
}
