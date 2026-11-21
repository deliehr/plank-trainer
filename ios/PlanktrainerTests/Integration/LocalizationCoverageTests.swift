import Foundation
import Testing
@testable import Planktrainer

@Suite("LocalizationCoverage")
struct LocalizationCoverageTests {
    @Test(arguments: LocalizationTable.allCases, ["de", "en"])
    func tableIsNotEmpty(table: LocalizationTable, localization: String) {
        #expect(!entries(in: table, localization: localization).isEmpty)
    }

    @Test(arguments: LocalizationTable.allCases, ["de", "en"])
    func noValueIsEmpty(table: LocalizationTable, localization: String) {
        let blank = entries(in: table, localization: localization).filter { value in
            (value.value as? String)?.isEmpty == true
        }
        #expect(blank.isEmpty)
    }

    private func entries(in table: LocalizationTable, localization: String) -> [String: Any] {
        var result: [String: Any] = [:]
        for fileExtension in ["strings", "stringsdict"] {
            guard let url = Bundle.main.url(
                forResource: table.rawValue, withExtension: fileExtension,
                subdirectory: nil, localization: localization
            ), let dictionary = NSDictionary(contentsOf: url) as? [String: Any] else { continue }
            result.merge(dictionary) { current, _ in current }
        }
        return result
    }
}
