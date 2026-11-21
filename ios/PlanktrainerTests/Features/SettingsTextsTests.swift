import Foundation
import Testing
@testable import Planktrainer

@Suite struct SettingsTextsTests {
    nonisolated static let keys: [String.LocalizationValue] = [
        "settings.title",
        "settings.appearance",
        "settings.appearance.system",
        "settings.appearance.light",
        "settings.appearance.dark",
        "settings.coach.header",
        "settings.coach.calm",
        "settings.coach.calm.description",
        "settings.coach.demanding",
        "settings.coach.demanding.description",
        "settings.coach.cheeky",
        "settings.coach.cheeky.description",
        "settings.coach.off",
        "settings.coach.off.description",
        "settings.postureHints",
        "settings.postureHints.footer",
        "settings.haptics",
        "settings.haptics.footer",
        "settings.about",
        "about.title",
        "about.version",
        "about.license",
        "about.license.value",
        "about.sourceCode",
    ]

    @Test(arguments: ["de", "en"], keys)
    func resolvesKey(language: String, key: String.LocalizationValue) {
        let resolved = L10n.string(key, table: .settings, locale: Locale(identifier: language))
        #expect(!resolved.isEmpty)
        #expect(!resolved.hasPrefix("settings."))
        #expect(!resolved.hasPrefix("about."))
    }
}
