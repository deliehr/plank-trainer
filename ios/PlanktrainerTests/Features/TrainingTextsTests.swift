import Foundation
import Testing
@testable import Planktrainer

@Suite struct TrainingTextsTests {
    nonisolated static let keys: [String] = [
        "training.title",
        "training.summary.record %@",
        "training.summary.last %@ %@",
        "training.sessionTime.header",
        "training.minutes",
        "training.seconds",
        "training.minutes.unit",
        "training.seconds.unit",
        "training.preparation",
        "training.preparation.value %lld",
        "training.start",
        "training.start.hint",
    ]

    @Test(arguments: keys, ["de", "en"])
    func keyResolvesToText(key: String, language: String) {
        let resolved = L10n.string(String.LocalizationValue(key), table: .training, locale: Locale(identifier: language))
        #expect(resolved != key)
        #expect(!resolved.isEmpty)
    }
}
