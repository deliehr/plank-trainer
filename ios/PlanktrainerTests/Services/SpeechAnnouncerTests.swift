import Foundation
import Testing
@testable import Planktrainer

final class FakeAudioSession: AudioSessionControlling {
    struct Failure: Error {}

    var failsConfigure = false
    var failsActivate = false
    private(set) var configureCalls = 0
    private(set) var activateCalls = 0
    private(set) var deactivateCalls = 0

    func configureForAnnouncements() throws {
        configureCalls += 1
        if failsConfigure { throw Failure() }
    }

    func activate() throws {
        activateCalls += 1
        if failsActivate { throw Failure() }
    }

    func deactivate() throws {
        deactivateCalls += 1
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

    @Test func speakThrowsUnavailableWhenActivationFails() {
        let session = FakeAudioSession()
        session.failsActivate = true
        let announcer = SpeechAnnouncer(audioSession: session, locale: Locale(identifier: "en"))

        #expect(throws: AnnouncerError.unavailable) { try announcer.speak("Hello") }
        #expect(session.activateCalls == 1)
        #expect(session.deactivateCalls == 0)
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
