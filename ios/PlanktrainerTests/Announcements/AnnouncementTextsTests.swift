import Foundation
import Testing
@testable import Planktrainer

@Suite struct AnnouncementTextsTests {
    nonisolated struct Case: Sendable {
        let language: String
        let phrase: FixedPhrase
        let argument: String?
        let expected: String
    }

    nonisolated static let fixedCases: [Case] = [
        Case(language: "de", phrase: .prepare, argument: nil, expected: "Mach dich bereit."),
        Case(language: "de", phrase: .startWithoutCoach, argument: "1 Minute", expected: "Planking Session gestartet, noch 1 Minute."),
        Case(language: "de", phrase: .complete, argument: nil, expected: "Planking Session abgeschlossen."),
        Case(language: "de", phrase: .stoppedWithoutCoach, argument: "42 Sekunden", expected: "Gestoppt nach 42 Sekunden."),
        Case(language: "de", phrase: .startWithoutCoach, argument: nil, expected: "Planking Session gestartet, noch 0 Sekunden."),
        Case(language: "en", phrase: .prepare, argument: nil, expected: "Get ready."),
        Case(language: "en", phrase: .startWithoutCoach, argument: "1 minute", expected: "Planking session started, 1 minute to go."),
        Case(language: "en", phrase: .complete, argument: nil, expected: "Planking session complete."),
        Case(language: "en", phrase: .stoppedWithoutCoach, argument: "42 seconds", expected: "Stopped after 42 seconds."),
        Case(language: "en", phrase: .stoppedWithoutCoach, argument: nil, expected: "Stopped after 0 seconds."),
    ]

    @Test(arguments: fixedCases)
    func resolvesFixedPhrase(testCase: Case) {
        let texts = AnnouncementTexts(locale: Locale(identifier: testCase.language))
        #expect(texts.fixed(testCase.phrase, argument: testCase.argument) == testCase.expected)
    }

    @Test(arguments: ["de", "en"])
    func countdownIsNumberOnly(language: String) {
        let texts = AnnouncementTexts(locale: Locale(identifier: language))
        #expect(texts.countdown(5) == "5")
    }

    @Test(arguments: ["de", "en"])
    func delegatesDurationToFormatter(language: String) {
        let locale = Locale(identifier: language)
        let formatter = SpokenDurationFormatter(locale: locale)
        let texts = AnnouncementTexts(locale: locale)
        #expect(texts.duration(150) == formatter.duration(150))
        #expect(texts.timeRemaining(150) == formatter.timeRemaining(150))
    }
}
