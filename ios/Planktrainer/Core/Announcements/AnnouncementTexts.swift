import Foundation

struct AnnouncementTexts: AnnouncementTextProviding {
    private let locale: Locale
    private let formatter: SpokenDurationFormatter

    init(locale: Locale = AppLocale.current) {
        self.locale = locale
        formatter = SpokenDurationFormatter(locale: locale)
    }

    func duration(_ seconds: Int) -> String { formatter.duration(seconds) }

    func timeRemaining(_ seconds: Int) -> String { formatter.timeRemaining(seconds) }

    func countdown(_ number: Int) -> String { number.formatted(.number.locale(locale)) }

    func fixed(_ phrase: FixedPhrase, argument: String?) -> String {
        let spokenArgument = argument ?? formatter.duration(0)
        return switch phrase {
        case .prepare: string("announcement.prepare")
        case .startWithoutCoach: string("announcement.startWithoutCoach \(spokenArgument)")
        case .complete: string("announcement.complete")
        case .stoppedWithoutCoach: string("announcement.stoppedWithoutCoach \(spokenArgument)")
        }
    }

    private func string(_ key: String.LocalizationValue) -> String {
        L10n.string(key, table: .announcements, locale: locale)
    }
}
