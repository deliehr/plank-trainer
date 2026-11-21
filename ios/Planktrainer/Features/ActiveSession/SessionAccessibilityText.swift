import Foundation

enum SessionAccessibilityText {
    static func timerValue(
        display: SessionTimerDisplay,
        coachLine: String?,
        locale: Locale = AppLocale.current
    ) -> String {
        let remaining = TimeText.accessibleDuration(display.remainingSeconds, locale: locale)
        let total = TimeText.accessibleDuration(display.totalSeconds, locale: locale)
        let elapsed = TimeText.accessibleDuration(display.elapsedSeconds, locale: locale)
        var parts = [
            "\(remaining) \(L10n.string("display.of \(total)", table: .sessionDisplay, locale: locale))",
            L10n.string("display.elapsed \(elapsed)", table: .sessionDisplay, locale: locale)
        ]
        if display.isPaused {
            parts.append(L10n.string("display.paused", table: .sessionDisplay, locale: locale))
        }
        if display.extensionSeconds > 0 {
            let extended = TimeText.accessibleDuration(display.extensionSeconds, locale: locale)
            parts.append(L10n.string("display.extended \(extended)", table: .sessionDisplay, locale: locale))
        }
        if let coachLine {
            parts.append(coachLine)
        }
        return parts.joined(separator: ". ")
    }

    static func resultLabel(
        result: SessionResult,
        previousRecordSeconds: Int?,
        locale: Locale = AppLocale.current
    ) -> String {
        let headlineKey: String.LocalizationValue = result.isGoalReached
            ? "display.result.headline.reached"
            : "display.result.headline.missed"
        let planned = TimeText.accessibleDuration(result.configuration.plannedSeconds, locale: locale)
        var parts = [
            L10n.string(headlineKey, table: .sessionDisplay, locale: locale),
            TimeText.accessibleDuration(result.achievedSeconds, locale: locale),
            L10n.string("display.result.goal \(planned)", table: .sessionDisplay, locale: locale)
        ]
        if !result.isGoalReached {
            let missing = result.configuration.plannedSeconds - result.achievedSeconds
            parts.append(L10n.string("display.result.remainingToGoal \(missing)", table: .sessionDisplay, locale: locale))
        }
        if result.isNewRecord, let previousRecordSeconds {
            let difference = result.achievedSeconds - previousRecordSeconds
            let previous = TimeText.accessibleDuration(previousRecordSeconds, locale: locale)
            parts.append(L10n.string("display.result.overRecord \(difference) \(previous)", table: .sessionDisplay, locale: locale))
        }
        if result.isNewRecord {
            parts.append(L10n.string("common.newRecord", table: .common, locale: locale))
        }
        if !result.isGoalReached {
            parts.append(L10n.string("display.result.saved", table: .sessionDisplay, locale: locale))
        }
        return parts.joined(separator: ". ")
    }
}
