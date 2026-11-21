import Foundation
import Testing
@testable import Planktrainer

@Suite struct ActiveSessionTextsTests {
    nonisolated static let keys = [
        "active.cancel", "active.pause", "active.resume", "active.stop", "active.stop.hint",
        "active.extend", "active.extend.accessibility", "active.prepare.caption",
        "active.resuming.caption", "active.discard.title", "active.discard.message",
        "active.discard.confirm", "active.discard.keep", "active.saveError.title",
        "active.resuming.hint", "active.prepare.posture", "active.stop.subtitle", "active.stop.combined",
        "active.announcementsPaused"
    ]

    @Test(arguments: keys, ["de", "en"])
    func keyIsTranslated(key: String, language: String) {
        let value = L10n.string(String.LocalizationValue(key), table: .activeSession, locale: Locale(identifier: language))
        #expect(value != key)
    }

    @Test func germanAndEnglishDiffer() {
        let de = L10n.string("active.cancel", table: .activeSession, locale: Locale(identifier: "de"))
        let en = L10n.string("active.cancel", table: .activeSession, locale: Locale(identifier: "en"))
        #expect(de == "Abbrechen")
        #expect(en == "Cancel")
    }

    @Test func germanValues() {
        func text(_ key: String.LocalizationValue) -> String {
            L10n.string(key, table: .activeSession, locale: Locale(identifier: "de"))
        }
        #expect(text("active.prepare.goal \("1:30")") == "Ziel 1:30 · Start mit Ansage")
        #expect(text("active.coach \("Frech")") == "Coach: Frech")
        #expect(text("active.coachLine \("Hallo")") == "„Hallo“")
        #expect(text("active.discard.message") == "Die bisherige Zeit wird nicht gespeichert.")
        #expect(text("active.resuming.caption") == "Weiter in …")
        #expect(text("active.stop.combined") == "Stop & speichern")
    }

    @Test func englishValues() {
        func text(_ key: String.LocalizationValue) -> String {
            L10n.string(key, table: .activeSession, locale: Locale(identifier: "en"))
        }
        #expect(text("active.prepare.goal \("1:30")") == "Goal 1:30 · Starts with an announcement")
        #expect(text("active.coachLine \("Hi")") == "“Hi”")
        #expect(text("active.stop.combined") == "Stop & Save")
    }
}
