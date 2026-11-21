import Foundation
import Testing
@testable import Planktrainer

@MainActor
@Suite struct ActiveSessionAccessibilityTextTests {
    private let english = Locale(identifier: "en")

    private func result(achieved: Int, planned: Int = 90, isNewRecord: Bool = false) -> SessionResult {
        SessionResult(
            configuration: SessionConfiguration(plannedSeconds: planned, preparationSeconds: 10),
            startedAt: Date(timeIntervalSince1970: 0),
            endedAt: Date(timeIntervalSince1970: 0),
            extensionSeconds: 0,
            achievedSeconds: achieved,
            pauseCount: 0,
            outcome: .stopped,
            isNewRecord: isNewRecord
        )
    }

    @Test func runningValueNamesRemainingTotalElapsedAndCoachLine() {
        let display = SessionTimerDisplay(remainingSeconds: 56, elapsedSeconds: 34, totalSeconds: 90, extensionSeconds: 0, isPaused: false)
        let value = SessionAccessibilityText.timerValue(display: display, coachLine: "Keep going", locale: english)
        #expect(value.contains("56 seconds"))
        #expect(value.contains("of 1 minute, 30 seconds"))
        #expect(value.contains("34 seconds elapsed"))
        #expect(value.hasSuffix("Keep going"))
        #expect(!value.contains("Paused"))
    }

    @Test func pausedValueAnnouncesPausedState() {
        let display = SessionTimerDisplay(remainingSeconds: 56, elapsedSeconds: 34, totalSeconds: 90, extensionSeconds: 10, isPaused: true)
        let value = SessionAccessibilityText.timerValue(display: display, coachLine: nil, locale: english)
        #expect(value.contains("Paused"))
        #expect(value.contains("Extended by"))
    }

    @Test func missedResultMentionsRemainingAndSaved() {
        let label = SessionAccessibilityText.resultLabel(result: result(achieved: 58), previousRecordSeconds: nil, locale: english)
        #expect(label.contains("Well held"))
        #expect(label.contains("32 s to go"))
        #expect(label.contains("Saved to History"))
        #expect(!label.contains("New record"))
    }

    @Test func recordResultMentionsDifferenceAndBadge() {
        let label = SessionAccessibilityText.resultLabel(result: result(achieved: 105, isNewRecord: true), previousRecordSeconds: 90, locale: english)
        #expect(label.contains("Completed"))
        #expect(label.contains("15 s over the old record"))
        #expect(label.contains("New record!"))
        #expect(!label.contains("Saved to History"))
    }
}
