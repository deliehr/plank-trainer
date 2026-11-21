import Testing
@testable import Planktrainer

@Suite("AnnouncementModels")
struct AnnouncementModelsTests {
    @Test func estimatedDurationUsesCharactersPerSecond() {
        let announcement = ScheduledAnnouncement(elapsedSecond: 0, kind: .filler, text: String(repeating: "a", count: 14))
        #expect(announcement.estimatedDuration == 1.0)
    }

    @Test func oneOffsCollectOnlyPrefixOneOff() {
        let announcement = ScheduledAnnouncement(
            elapsedSecond: 30,
            kind: .timeRemaining(30),
            prefixKind: .halfway,
            text: "Halfway."
        )
        #expect(announcement.oneOffs == [.halfway])
    }

    @Test func closingInputGoalBoundary() {
        func input(achieved: Int) -> ClosingInput {
            ClosingInput(
                achievedSeconds: achieved,
                plannedSeconds: 60,
                isNewRecord: false,
                newRecordAlreadyAnnounced: false,
                style: .calm
            )
        }
        #expect(!input(achieved: 59).isGoalReached)
        #expect(input(achieved: 60).isGoalReached)
        #expect(input(achieved: 61).isGoalReached)
    }

    @Test(arguments: [(0, false), (1, true), (5, true), (6, false)])
    func finalCountdownRange(remaining: Int, expected: Bool) {
        let display = SessionTimerDisplay(
            remainingSeconds: remaining,
            elapsedSeconds: 0,
            totalSeconds: 60,
            extensionSeconds: 0,
            isPaused: false
        )
        #expect(display.isFinalCountdown == expected)
    }

    @Test func terminalPhases() {
        #expect(SessionPhase.finished(.completed).isTerminal)
        #expect(SessionPhase.finished(.stopped).isTerminal)
        #expect(SessionPhase.cancelled.isTerminal)
        #expect(!SessionPhase.preparing.isTerminal)
        #expect(!SessionPhase.running.isTerminal)
        #expect(!SessionPhase.paused.isTerminal)
        #expect(!SessionPhase.resuming.isTerminal)
    }
}
