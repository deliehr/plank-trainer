import Foundation
import Testing
@testable import Planktrainer

@Suite struct PhraseSelectorTests {
    nonisolated struct Combination: Sendable, CustomTestStringConvertible {
        let style: CoachStyle
        let occasion: CoachOccasion
        let language: String

        var testDescription: String { "\(style.rawValue)/\(occasion.rawValue)/\(language)" }

        static let all: [Combination] = CoachStyle.allCases
            .filter { $0 != .off }
            .flatMap { style in
                CoachOccasion.allCases.flatMap { occasion in
                    ["de", "en"].map { Combination(style: style, occasion: occasion, language: $0) }
                }
            }
    }

    @Test(arguments: Combination.all)
    func everyCatalogKeyResolvesToText(combination: Combination) {
        let keys = PhraseCatalog.keys(for: combination.occasion, style: combination.style)
        #expect(!keys.isEmpty)
        for key in keys {
            let text = L10n.string(String.LocalizationValue(key), table: .coach, locale: Locale(identifier: combination.language))
            #expect(!text.isEmpty)
            #expect(text != key)
        }
    }

    @Test(arguments: ["de", "en"])
    func postureKeysResolveInBothLanguages(language: String) {
        #expect(PhraseCatalog.postureHintKeys.count == 10)
        for key in PhraseCatalog.postureHintKeys {
            let text = L10n.string(String.LocalizationValue(key), table: .coach, locale: Locale(identifier: language))
            #expect(!text.isEmpty)
            #expect(text != key)
        }
    }

    @Test func offStyleProducesNoPhrase() {
        let selector = makeSelector()
        for occasion in CoachOccasion.allCases {
            #expect(selector.coachPhrase(occasion, style: .off, argument: nil) == nil)
            #expect(PhraseCatalog.keys(for: occasion, style: .off).isEmpty)
        }
    }

    @Test func startPhraseContainsArgument() {
        let selector = makeSelector()
        let text = selector.coachPhrase(.start, style: .demanding, argument: "1 Minute")
        #expect(text?.contains("1 Minute") == true)
    }

    @Test func stoppedPhraseContainsArgument() {
        let selector = makeSelector()
        let text = selector.coachPhrase(.stopped, style: .cheeky, argument: "42 Sekunden")
        #expect(text?.contains("42 Sekunden") == true)
    }

    @Test(arguments: ["de", "en"])
    func noArgumentPhraseLeavesNoPlaceholder(language: String) {
        let selector = makeSelector(language: language)
        for style in CoachStyle.allCases where style != .off {
            for occasion in CoachOccasion.allCases {
                for _ in PhraseCatalog.keys(for: occasion, style: style) {
                    let text = selector.coachPhrase(occasion, style: style, argument: "X")
                    #expect(text?.contains("%@") == false)
                }
            }
        }
    }

    @Test func doesNotRepeatWithinOneCycle() {
        let selector = makeSelector()
        let texts = (0..<4).compactMap { _ in selector.coachPhrase(.start, style: .calm, argument: "1 Minute") }
        #expect(Set(texts).count == 4)
    }

    @Test func sameSeedGivesSameFillerSequence() {
        let first = makeSelector(seed: 5)
        let second = makeSelector(seed: 5)
        let firstTexts = (0..<10).map { _ in first.coachPhrase(.filler, style: .cheeky, argument: nil) }
        let secondTexts = (0..<10).map { _ in second.coachPhrase(.filler, style: .cheeky, argument: nil) }
        #expect(firstTexts == secondTexts)
    }

    @Test func postureHintsDoNotRepeatWithinOneCycle() {
        let selector = makeSelector()
        let texts = (0..<10).compactMap { _ in selector.postureHint() }
        #expect(Set(texts).count == 10)
    }

    @Test func verbatimSamples() {
        #expect(L10n.string("coach.demanding.filler.03", table: .coach, locale: Locale(identifier: "de")) == "Nicht nachlassen!")
        #expect(L10n.string("coach.demanding.filler.03", table: .coach, locale: Locale(identifier: "en")) == "Don't let up!")
        #expect(L10n.string("coach.posture.01", table: .coach, locale: Locale(identifier: "de")) == "Bauch anspannen.")
    }

    private func makeSelector(language: String = "de", seed: UInt64 = 1) -> PhraseSelector {
        PhraseSelector(locale: Locale(identifier: language), generator: SplitMix64(seed: seed))
    }
}
