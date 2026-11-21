import Foundation

nonisolated enum HistoryDateText {
    static func sessionDate(
        _ date: Date,
        now: Date = .now,
        locale: Locale = AppLocale.current,
        calendar: Calendar = .current
    ) -> String {
        let timeFormatter = makeFormatter(locale: locale, calendar: calendar)
        timeFormatter.timeStyle = .short
        let time = timeFormatter.string(from: date)
        return "\(dayText(date, now: now, locale: locale, calendar: calendar)), \(time)"
    }

    private static func dayText(_ date: Date, now: Date, locale: Locale, calendar: Calendar) -> String {
        let dayOffset = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day
        if let dayOffset, (-1...0).contains(dayOffset) {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.dateTimeStyle = .named
            formatter.formattingContext = .beginningOfSentence
            return formatter.localizedString(from: DateComponents(day: dayOffset))
        }
        let formatter = makeFormatter(locale: locale, calendar: calendar)
        formatter.setLocalizedDateFormatFromTemplate("EEEdMMM")
        return formatter.string(from: date)
    }

    private static func makeFormatter(locale: Locale, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        return formatter
    }
}
