import Foundation

nonisolated struct SpokenDurationFormatter: Sendable {
    let locale: Locale

    func duration(_ seconds: Int) -> String {
        let seconds = max(seconds, 0)
        guard seconds >= 60 else { return string("duration.seconds \(seconds)") }
        let minutes = minutesText(seconds / 60)
        let rest = seconds % 60
        guard rest != 0 else { return minutes }
        return string("duration.minutesAndSeconds \(minutes) \(rest)")
    }

    func timeRemaining(_ seconds: Int) -> String {
        string("announcement.timeRemaining \(duration(seconds))")
    }

    private func minutesText(_ minutes: Int) -> String {
        string("duration.minutes \(minutes)")
    }

    private func string(_ key: String.LocalizationValue) -> String {
        L10n.string(key, table: .announcements, locale: locale)
    }
}
