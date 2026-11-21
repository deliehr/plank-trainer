import Foundation
import Testing
@testable import Planktrainer

@Suite struct SessionDisplayTextsTests {
    nonisolated private static let languages = ["de", "en"]

    private func text(_ key: String.LocalizationValue, _ language: String) -> String {
        L10n.string(key, table: .sessionDisplay, locale: Locale(identifier: language))
    }

    @Test(arguments: languages)
    func plainKeysResolve(language: String) {
        let values = [
            text("display.paused", language),
            text("display.remaining", language),
            text("display.result.done", language)
        ]
        #expect(values.allSatisfy { !$0.isEmpty && !$0.hasPrefix("display.") })
    }

    @Test func englishValues() {
        #expect(text("display.paused", "en") == "Paused")
        #expect(text("display.remaining", "en") == "Remaining time")
        #expect(text("display.elapsed \("0:30")", "en") == "0:30 elapsed")
        #expect(text("display.extended \("30 sec")", "en") == "Extended by 30 sec")
        #expect(text("display.countdown.accessibility \(3)", "en") == "Starting in 3")
        #expect(text("display.result.goal \("1:00")", "en") == "Goal: 1:00")
        #expect(text("display.result.done", "en") == "Done")
    }

    @Test func germanValues() {
        #expect(text("display.paused", "de") == "Pausiert")
        #expect(text("display.remaining", "de") == "Restzeit")
        #expect(text("display.elapsed \("0:30")", "de") == "0:30 vergangen")
        #expect(text("display.extended \("30 Sek.")", "de") == "Verlängert um 30 Sek.")
        #expect(text("display.countdown.accessibility \(3)", "de") == "Start in 3")
        #expect(text("display.result.goal \("1:00")", "de") == "Ziel: 1:00")
        #expect(text("display.result.done", "de") == "Fertig")
    }
}
