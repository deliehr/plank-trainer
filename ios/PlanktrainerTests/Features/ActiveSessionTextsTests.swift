import Foundation
import Testing
@testable import Planktrainer

@Suite struct ActiveSessionTextsTests {
    nonisolated static let keys = [
        "active.cancel", "active.pause", "active.resume", "active.stop", "active.stop.hint",
        "active.extend", "active.extend.accessibility", "active.prepare.caption",
        "active.resuming.caption", "active.discard.title", "active.discard.message",
        "active.discard.confirm", "active.discard.keep", "active.saveError.title"
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
}
