import Foundation
import Testing
@testable import Planktrainer

@Suite struct HistoryTextsTests {
    nonisolated static let keys: [String.LocalizationValue] = [
        "history.title",
        "history.chart.title",
        "history.chart.summary \("1:30")",
        "history.chart.axis.session",
        "history.chart.axis.time",
        "history.row.result \("1:30") \("2:00")",
        "history.row.accessibility \("Today") \("1 minute") \("2 minutes")",
        "history.empty.title",
        "history.empty.message",
        "history.empty.action",
        "history.deleteError.title",
    ]

    @Test(arguments: ["de", "en"], keys)
    func resolvesKey(language: String, key: String.LocalizationValue) {
        let resolved = L10n.string(key, table: .history, locale: Locale(identifier: language))
        #expect(!resolved.isEmpty)
        #expect(!resolved.hasPrefix("history."))
    }

    @Test func resolvesAccessibilityFormatInBothLanguages() {
        let key: String.LocalizationValue = "history.row.accessibility \("Today") \("1 minute") \("2 minutes")"
        #expect(L10n.string(key, table: .history, locale: Locale(identifier: "en")) == "Today, 1 minute of 2 minutes")
        #expect(L10n.string(key, table: .history, locale: Locale(identifier: "de")) == "Today, 1 minute von 2 minutes")
    }
}
