import Foundation
import Testing
@testable import Planktrainer

@Suite struct LocalizationCompletenessTests {
    @Test(arguments: LocalizationTable.allCases)
    func germanAndEnglishHaveSameKeys(table: LocalizationTable) {
        #expect(keys(in: table, localization: "de") == keys(in: table, localization: "en"))
    }

    @Test func bundleContainsGermanAndEnglish() {
        #expect(Bundle.main.localizations.contains("de"))
        #expect(Bundle.main.localizations.contains("en"))
    }

    @Test func resolvesTabTitleInRequestedLanguage() {
        #expect(L10n.string("tab.history", table: .app, locale: Locale(identifier: "de")) == "Verlauf")
        #expect(L10n.string("tab.history", table: .app, locale: Locale(identifier: "en")) == "History")
    }

    private func keys(in table: LocalizationTable, localization: String) -> Set<String> {
        var result = Set<String>()
        for fileExtension in ["strings", "stringsdict"] {
            guard let url = Bundle.main.url(
                forResource: table.rawValue, withExtension: fileExtension,
                subdirectory: nil, localization: localization
            ), let dictionary = NSDictionary(contentsOf: url) as? [String: Any] else { continue }
            result.formUnion(dictionary.keys)
        }
        return result
    }
}
