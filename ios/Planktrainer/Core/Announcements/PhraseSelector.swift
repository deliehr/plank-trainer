import Foundation

final class PhraseSelector: CoachPhraseProviding {
    private struct BagID: Hashable {
        let style: CoachStyle
        let occasion: CoachOccasion
    }

    private let locale: Locale
    private var generator: SplitMix64
    private var bags: [BagID: ShuffleBag<String>] = [:]
    private var postureBag = ShuffleBag(PhraseCatalog.postureHintKeys)

    init(locale: Locale, generator: SplitMix64) {
        self.locale = locale
        self.generator = generator
    }

    func coachPhrase(_ occasion: CoachOccasion, style: CoachStyle, argument: String?) -> String? {
        guard style != .off else { return nil }
        let id = BagID(style: style, occasion: occasion)
        var bag = bags[id] ?? ShuffleBag(PhraseCatalog.keys(for: occasion, style: style))
        let key = bag.next(using: &generator)
        bags[id] = bag
        guard let key else { return nil }
        let template = resolve(key)
        guard let argument else { return template }
        return String(format: template, locale: locale, argument)
    }

    func postureHint() -> String? {
        postureBag.next(using: &generator).map(resolve)
    }

    private func resolve(_ key: String) -> String {
        L10n.string(String.LocalizationValue(key), table: .coach, locale: locale)
    }
}
