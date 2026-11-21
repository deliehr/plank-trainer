import Foundation

nonisolated enum TimeText {
    static func clock(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let remainder = clamped % 60
        return "\(clamped / 60):" + (remainder < 10 ? "0" : "") + "\(remainder)"
    }

    static func accessibleDuration(_ seconds: Int, locale: Locale = AppLocale.current) -> String {
        duration(seconds, width: .wide, locale: locale)
    }

    static func compactDuration(_ seconds: Int, locale: Locale = AppLocale.current) -> String {
        duration(seconds, width: .abbreviated, locale: locale)
    }

    static func relativeDateTime(
        _ date: Date,
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

    private static func duration(
        _ seconds: Int,
        width: Duration.UnitsFormatStyle.UnitWidth,
        locale: Locale
    ) -> String {
        Duration.seconds(max(0, seconds)).formatted(
            .units(allowed: [.minutes, .seconds], width: width).locale(locale)
        )
    }
}
