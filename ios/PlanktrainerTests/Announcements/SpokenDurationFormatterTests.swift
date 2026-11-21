import Foundation
import Testing
@testable import Planktrainer

@Suite struct SpokenDurationFormatterTests {
    nonisolated struct Case: Sendable {
        let language: String
        let seconds: Int
        let expected: String
    }

    nonisolated static let durationCases: [Case] = [
        Case(language: "de", seconds: 45, expected: "45 Sekunden"),
        Case(language: "de", seconds: 1, expected: "1 Sekunde"),
        Case(language: "de", seconds: 60, expected: "1 Minute"),
        Case(language: "de", seconds: 90, expected: "1 Minute 30"),
        Case(language: "de", seconds: 120, expected: "2 Minuten"),
        Case(language: "de", seconds: 150, expected: "2 Minuten 30"),
        Case(language: "de", seconds: 600, expected: "10 Minuten"),
        Case(language: "de", seconds: 0, expected: "0 Sekunden"),
        Case(language: "de", seconds: -5, expected: "0 Sekunden"),
        Case(language: "en", seconds: 45, expected: "45 seconds"),
        Case(language: "en", seconds: 1, expected: "1 second"),
        Case(language: "en", seconds: 60, expected: "1 minute"),
        Case(language: "en", seconds: 90, expected: "1 minute 30"),
        Case(language: "en", seconds: 120, expected: "2 minutes"),
        Case(language: "en", seconds: 150, expected: "2 minutes 30"),
        Case(language: "en", seconds: 600, expected: "10 minutes"),
        Case(language: "en", seconds: 0, expected: "0 seconds"),
    ]

    nonisolated static let timeRemainingCases: [Case] = [
        Case(language: "de", seconds: 45, expected: "Noch 45 Sekunden."),
        Case(language: "de", seconds: 60, expected: "Noch 1 Minute."),
        Case(language: "de", seconds: 90, expected: "Noch 1 Minute 30."),
        Case(language: "de", seconds: 150, expected: "Noch 2 Minuten 30."),
        Case(language: "de", seconds: 120, expected: "Noch 2 Minuten."),
        Case(language: "en", seconds: 45, expected: "45 seconds to go."),
        Case(language: "en", seconds: 60, expected: "1 minute to go."),
        Case(language: "en", seconds: 90, expected: "1 minute 30 to go."),
        Case(language: "en", seconds: 150, expected: "2 minutes 30 to go."),
        Case(language: "en", seconds: 120, expected: "2 minutes to go."),
    ]

    @Test(arguments: durationCases)
    func formatsDuration(testCase: Case) {
        let formatter = SpokenDurationFormatter(locale: Locale(identifier: testCase.language))
        #expect(formatter.duration(testCase.seconds) == testCase.expected)
    }

    @Test(arguments: timeRemainingCases)
    func formatsTimeRemaining(testCase: Case) {
        let formatter = SpokenDurationFormatter(locale: Locale(identifier: testCase.language))
        #expect(formatter.timeRemaining(testCase.seconds) == testCase.expected)
    }
}
