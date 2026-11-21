import Foundation

enum LocalizationTable: String, CaseIterable, Sendable {
    case app = "App"
    case common = "Common"
    case errors = "Errors"
    case announcements = "Announcements"
    case coach = "Coach"
    case training = "Training"
    case history = "History"
    case sessionDetail = "SessionDetail"
    case activeSession = "ActiveSession"
    case sessionDisplay = "SessionDisplay"
    case settings = "Settings"
}

nonisolated enum AppLocale {
    static var current: Locale {
        Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
    }
}

nonisolated enum L10n {
    static func string(
        _ key: String.LocalizationValue,
        table: LocalizationTable,
        locale: Locale = AppLocale.current
    ) -> String {
        var resource = LocalizedStringResource(key, table: table.rawValue)
        resource.locale = locale
        return String(localized: resource)
    }
}
