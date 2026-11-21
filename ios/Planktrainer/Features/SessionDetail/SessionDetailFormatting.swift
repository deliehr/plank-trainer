import Foundation

nonisolated enum SessionDetailFormatting {
    static func title(
        for date: Date,
        locale: Locale = AppLocale.current,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }

    static func fullDate(
        _ date: Date,
        locale: Locale = AppLocale.current,
        timeZone: TimeZone = .current
    ) -> String {
        let style = Date.FormatStyle(date: .abbreviated, time: .shortened, locale: locale, timeZone: timeZone)
        return date.formatted(style)
    }
}
