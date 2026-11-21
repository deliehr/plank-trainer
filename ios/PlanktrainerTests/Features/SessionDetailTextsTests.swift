import Foundation
import Testing
@testable import Planktrainer

@Suite struct SessionDetailTextsTests {
    nonisolated private static let keys = [
        "detail.ring.label", "detail.date", "detail.preparation", "detail.pauses", "detail.extension",
        "detail.recordGap", "detail.repeat", "detail.notFound.title", "detail.none",
    ]

    @Test(arguments: ["de", "en"], keys)
    func resolvesPlainKeys(language: String, key: String) {
        let value = L10n.string(String.LocalizationValue(key), table: .sessionDetail, locale: Locale(identifier: language))
        #expect(value != key)
    }

    @Test func resolvesParameterizedKeys() {
        let de = Locale(identifier: "de")
        let en = Locale(identifier: "en")
        #expect(L10n.string("detail.ring.value \("1:30") \("2:00")", table: .sessionDetail, locale: de) == "1:30 von 2:00")
        #expect(L10n.string("detail.ring.value \("1:30") \("2:00")", table: .sessionDetail, locale: en) == "1:30 of 2:00")
        #expect(L10n.string("detail.ring.of \("1:30")", table: .sessionDetail, locale: de) == "von 1:30")
        #expect(L10n.string("detail.ring.of \("1:30")", table: .sessionDetail, locale: en) == "of 1:30")
        #expect(L10n.string("detail.extension.added \("10 s")", table: .sessionDetail, locale: de) == "+10 s")
        #expect(L10n.string("detail.recordGap.below \("12 s")", table: .sessionDetail, locale: de) == "12 s unter deinem Rekord")
        #expect(L10n.string("detail.recordGap.below \("12 s")", table: .sessionDetail, locale: en) == "12 s below your record")
    }
}
