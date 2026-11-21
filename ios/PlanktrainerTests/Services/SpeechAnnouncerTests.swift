import Foundation
import Synchronization
import Testing
@testable import Planktrainer

nonisolated final class FakeAudioSession: AudioSessionControlling {
    struct Failure: Error {}

    private struct State {
        var failsConfigure = false
        var failsActivate = false
        var configureCalls = 0
        var activateCalls = 0
        var deactivateCalls = 0
    }

    private let state = Mutex(State())

    var failsConfigure: Bool {
        get { state.withLock { $0.failsConfigure } }
        set { state.withLock { $0.failsConfigure = newValue } }
    }

    var failsActivate: Bool {
        get { state.withLock { $0.failsActivate } }
        set { state.withLock { $0.failsActivate = newValue } }
    }

    var configureCalls: Int { state.withLock { $0.configureCalls } }
    var activateCalls: Int { state.withLock { $0.activateCalls } }
    var deactivateCalls: Int { state.withLock { $0.deactivateCalls } }

    func configureForAnnouncements() throws {
        let fails = state.withLock { state in
            state.configureCalls += 1
            return state.failsConfigure
        }
        if fails { throw Failure() }
    }

    func activate() throws {
        let fails = state.withLock { state in
            state.activateCalls += 1
            return state.failsActivate
        }
        if fails { throw Failure() }
    }

    func deactivate() throws {
        state.withLock { $0.deactivateCalls += 1 }
    }
}

private func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
    }
}

@Suite struct SpeechAnnouncerTests {
    @Test func prepareThrowsUnavailableWhenConfigurationFails() {
        let session = FakeAudioSession()
        session.failsConfigure = true
        let announcer = SpeechAnnouncer(audioSession: session, locale: Locale(identifier: "en"))

        #expect(throws: AnnouncerError.unavailable) { try announcer.prepare() }
        #expect(session.configureCalls == 1)
    }

    @Test func speakThrowsUnavailableAfterActivationFailed() async throws {
        let session = FakeAudioSession()
        session.failsActivate = true
        let announcer = SpeechAnnouncer(audioSession: session, locale: Locale(identifier: "en"))

        try announcer.speak("Hello")
        try await waitUntil { announcer.isUnavailable }

        #expect(throws: AnnouncerError.unavailable) { try announcer.speak("Hello") }
        #expect(session.deactivateCalls == 0)
    }

    @Test func speakSucceedsAgainAfterActivationRecovers() async throws {
        let session = FakeAudioSession()
        session.failsActivate = true
        let announcer = SpeechAnnouncer(audioSession: session, locale: Locale(identifier: "en"))
        try announcer.speak("Hello")
        try await waitUntil { announcer.isUnavailable }

        session.failsActivate = false
        #expect(throws: AnnouncerError.unavailable) { try announcer.speak("Hello") }
        try await waitUntil { !announcer.isUnavailable }

        #expect(session.activateCalls == 2)
        #expect(throws: Never.self) { try announcer.speak("Hello") }
    }

    @Test func stopSpeakingWithoutOutputHasNoEffect() {
        let session = FakeAudioSession()
        let announcer = SpeechAnnouncer(audioSession: session, locale: Locale(identifier: "en"))

        announcer.stopSpeaking()

        #expect(session.activateCalls == 0)
        #expect(session.deactivateCalls == 0)
    }

    @Test(arguments: [
        ("de", "de-AT", "de-AT"),
        ("de", "en-US", "de"),
        ("en", "en-GB", "en-GB"),
        ("en", "de-DE", "en")
    ])
    func voiceLanguagePrefersSystemRegionOfAppLanguage(appLanguage: String, system: String, expected: String) {
        #expect(SpeechAnnouncer.voiceLanguage(appLanguage: appLanguage, systemVoiceLanguage: system) == expected)
    }
}
