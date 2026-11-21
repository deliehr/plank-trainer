import Foundation
import Testing
@testable import Planktrainer

@MainActor
@Suite("SessionEngine")
struct SessionEngineTests {
    final class Harness {
        let clock = TestSessionClock()
        let announcer = FakeAnnouncer()
        let planner = FakePlanner()
        let engine: SessionEngine

        init(
            planned: Int = 30,
            preparation: Int = 5,
            history: SessionHistoryContext = .empty,
            extras: [ScheduledAnnouncement] = []
        ) {
            planner.extraItems = extras
            engine = SessionEngine(
                configuration: SessionConfiguration(plannedSeconds: planned, preparationSeconds: preparation),
                history: history,
                coachStyle: .calm,
                postureHintsEnabled: false,
                announcer: announcer,
                planner: planner,
                clock: clock
            )
        }

        func advance(_ seconds: Double) {
            PlanktrainerTests.advance(engine, clock, seconds: seconds)
        }

        func startRunning() {
            engine.start()
            advance(5)
        }
    }

    private static func item(_ second: Int, _ text: String, kind: AnnouncementKind = .filler) -> ScheduledAnnouncement {
        ScheduledAnnouncement(elapsedSecond: second, kind: kind, text: text)
    }

    @Test func startSpeaksPreparationAndEntersRunning() {
        let h = Harness()
        h.engine.start()
        #expect(h.engine.phase == .preparing)
        #expect(h.announcer.prepareCount == 1)
        #expect(h.announcer.spoken == ["P"])
        #expect(h.engine.preparationRemainingSeconds == 5)

        h.advance(2)
        #expect(h.announcer.spoken.last == "3")
        #expect(h.engine.hapticSignal?.haptic == .countdownTick)

        h.advance(3)
        #expect(h.engine.phase == .running)
        #expect(h.engine.hapticSignal?.haptic == .runningStarted)
        #expect(h.announcer.spoken.last == "A0")
        #expect(h.planner.planInputs.first?.trigger == .start)
        #expect(h.engine.elapsedSeconds == 0)
        #expect(h.engine.totalSeconds == 30)
    }

    @Test func actionsBeforeStartAreIgnored() {
        let h = Harness()
        h.engine.pause()
        h.advance(10)
        #expect(h.engine.phase == .preparing)
        #expect(h.engine.pauseCount == 0)
        #expect(h.announcer.spoken.isEmpty)
        #expect(h.planner.planInputs.isEmpty)
    }

    @Test func dueAnnouncementsAreSpokenOnce() {
        let h = Harness(extras: [Self.item(10, "B"), Self.item(20, "C")])
        h.startRunning()
        h.advance(10)
        #expect(h.announcer.spoken.filter { $0 == "B" }.count == 1)
        #expect(!h.announcer.spoken.contains("C"))
        h.advance(10)
        #expect(h.announcer.spoken.filter { $0 == "B" }.count == 1)
        #expect(h.announcer.spoken.filter { $0 == "C" }.count == 1)
    }

    @Test func staleAnnouncementsAreSkipped() {
        let h = Harness(extras: [Self.item(10, "B")])
        h.startRunning()
        h.clock.advance(by: .seconds(15))
        h.engine.tick()
        #expect(!h.announcer.spoken.contains("B"))
        #expect(h.engine.elapsedSeconds == 15)
    }

    @Test func completionProducesResult() throws {
        let h = Harness()
        h.startRunning()
        h.advance(30)
        #expect(h.engine.phase == .finished(.completed))
        let result = try #require(h.engine.result)
        #expect(result.achievedSeconds == 30)
        #expect(result.isGoalReached)
        #expect(result.startedAt == h.clock.baseDate.addingTimeInterval(5))
        #expect(result.endedAt == h.clock.baseDate.addingTimeInterval(35))
        #expect(h.planner.closingInputs == [
            ClosingInput(achievedSeconds: 30, plannedSeconds: 30, isNewRecord: false, newRecordAlreadyAnnounced: false, style: .calm)
        ])
        #expect(h.announcer.spoken.last == "END")
        #expect(h.engine.hapticSignal?.haptic == .completed)
    }

    @Test func pauseFreezesTimeAndResumeCountsDown() throws {
        let h = Harness()
        h.startRunning()
        h.advance(10)
        let fractionBefore = h.engine.remainingFraction()
        h.engine.pause()
        #expect(h.engine.phase == .paused)
        #expect(h.announcer.stopCount == 1)
        #expect(h.engine.pauseCount == 1)

        h.advance(60)
        #expect(h.engine.elapsedSeconds == 10)
        #expect(h.engine.remainingFraction() == fractionBefore)

        h.engine.resume()
        #expect(h.engine.phase == .resuming)
        #expect(h.announcer.spoken.last == "3")
        h.advance(1)
        #expect(h.announcer.spoken.last == "2")
        h.advance(1)
        #expect(h.announcer.spoken.last == "1")
        h.advance(1)
        #expect(h.engine.phase == .running)
        #expect(h.planner.planInputs.last?.trigger == .resume)
        #expect(h.engine.elapsedSeconds == 10)

        h.advance(20)
        let result = try #require(h.engine.result)
        #expect(result.achievedSeconds == 30)
        #expect(result.pauseCount == 1)
    }

    @Test func stopBeforeGoalRoundsDown() throws {
        let h = Harness()
        h.startRunning()
        h.advance(12.7)
        h.engine.stop()
        #expect(h.engine.phase == .finished(.stopped))
        let result = try #require(h.engine.result)
        #expect(result.achievedSeconds == 12)
        #expect(!result.isGoalReached)
        #expect(h.announcer.events.suffix(2) == [.stop, .speak("END")])
    }

    @Test func stopDuringExtensionCountsGoalAsReached() throws {
        let h = Harness()
        h.startRunning()
        h.advance(25)
        h.engine.extend()
        h.advance(10)
        h.engine.stop()
        let result = try #require(h.engine.result)
        #expect(result.achievedSeconds == 35)
        #expect(result.isGoalReached)
        #expect(result.extensionSeconds == 10)
    }

    @Test func extendWhileRunningReplansWithoutSpeaking() throws {
        let h = Harness(extras: [Self.item(8, "B", kind: .filler)])
        h.startRunning()
        h.advance(10)
        let spokenBefore = h.announcer.spoken
        h.engine.extend()
        #expect(h.engine.totalSeconds == 40)
        #expect(h.announcer.spoken == spokenBefore)
        let input = try #require(h.planner.planInputs.last)
        #expect(input.trigger == .extended)
        #expect(input.elapsedSeconds == 10)
        #expect(input.totalSeconds == 40)
        #expect(input.previous == PreviousAnnouncement(startSecond: 8, estimatedDuration: 1.0 / 14.0))
    }

    @Test func extendWhilePausedDefersPlanning() {
        let h = Harness()
        h.startRunning()
        h.advance(10)
        h.engine.pause()
        let planCount = h.planner.planInputs.count
        h.engine.extend()
        #expect(h.engine.totalSeconds == 40)
        #expect(h.planner.planInputs.count == planCount)
    }

    @Test(arguments: [0.0, 5.0, 12.0, 12.0 + 3.0])
    func cancelFromAnyActivePhase(secondsBeforeCancel: Double) {
        let h = Harness()
        h.engine.start()
        h.advance(secondsBeforeCancel)
        if h.engine.phase == .running, secondsBeforeCancel > 10 {
            h.engine.pause()
            h.engine.resume()
        }
        let stopsBefore = h.announcer.stopCount
        h.engine.cancel()
        #expect(h.engine.phase == .cancelled)
        #expect(h.engine.result == nil)
        #expect(h.announcer.stopCount == stopsBefore + 1)
    }

    @Test func cancelFromPaused() {
        let h = Harness()
        h.startRunning()
        h.engine.pause()
        let stopsBefore = h.announcer.stopCount
        h.engine.cancel()
        #expect(h.engine.phase == .cancelled)
        #expect(h.engine.result == nil)
        #expect(h.announcer.stopCount == stopsBefore + 1)
    }

    @Test func disallowedActionsChangeNothing() {
        let h = Harness()
        h.engine.start()
        h.engine.stop()
        h.engine.extend()
        h.engine.resume()
        #expect(h.engine.phase == .preparing)
        #expect(h.engine.extensionSeconds == 0)

        h.advance(5)
        h.engine.resume()
        #expect(h.engine.phase == .running)

        h.engine.pause()
        h.engine.pause()
        #expect(h.engine.pauseCount == 1)

        h.engine.cancel()
        let phase = h.engine.phase
        h.engine.stop()
        h.engine.extend()
        h.engine.pause()
        h.engine.resume()
        h.engine.start()
        h.advance(5)
        #expect(h.engine.phase == phase)
        #expect(h.engine.extensionSeconds == 0)
        #expect(h.engine.pauseCount == 1)
    }

    @Test func actionsAfterFinishDoNothing() throws {
        let h = Harness()
        h.startRunning()
        h.advance(30)
        let result = try #require(h.engine.result)
        h.engine.stop()
        h.engine.extend()
        h.engine.pause()
        h.engine.cancel()
        #expect(h.engine.phase == .finished(.completed))
        #expect(h.engine.result == result)
    }

    @Test func pauseDuringPreparationStartsRunFromScratchAfterResume() {
        let h = Harness()
        h.engine.start()
        h.advance(2)
        h.engine.pause()
        #expect(h.engine.phase == .paused)
        h.engine.resume()
        h.advance(3)
        #expect(h.engine.phase == .running)
        #expect(h.planner.planInputs.last?.trigger == .start)
        #expect(h.engine.hapticSignal?.haptic == .runningStarted)
        #expect(h.engine.elapsedSeconds == 0)
    }

    @Test(arguments: [(20 as Int?, true), (40, false), (nil, false)])
    func newRecordDetection(record: Int?, expected: Bool) throws {
        let h = Harness(history: SessionHistoryContext(recordSeconds: record, lastSession: nil))
        h.startRunning()
        h.advance(30)
        #expect(try #require(h.engine.result).isNewRecord == expected)
    }

    @Test func latestCoachLineTracksRunningAnnouncementsOnly() {
        let h = Harness(extras: [Self.item(10, "F10"), Self.item(12, "C", kind: .countdown(3))])
        h.engine.start()
        #expect(h.engine.latestCoachLine == nil)
        h.advance(5)
        #expect(h.engine.latestCoachLine == "A0")
        h.advance(10)
        #expect(h.engine.latestCoachLine == "F10")
        h.advance(2)
        #expect(h.engine.latestCoachLine == "F10")
        h.engine.pause()
        #expect(h.engine.latestCoachLine == "F10")
    }

    @Test func previousRecordSecondsExposesHistoryRecord() {
        let h = Harness(history: SessionHistoryContext(recordSeconds: 42, lastSession: nil))
        #expect(h.engine.previousRecordSeconds == 42)
        #expect(Harness().engine.previousRecordSeconds == nil)
    }

    @Test func newRecordAlreadyAnnouncedIsForwarded() {
        let h = Harness(
            history: SessionHistoryContext(recordSeconds: 10, lastSession: nil),
            extras: [Self.item(11, "R", kind: .newRecord)]
        )
        h.startRunning()
        h.advance(30)
        #expect(h.planner.closingInputs.first?.newRecordAlreadyAnnounced == true)
        #expect(h.planner.closingInputs.first?.isNewRecord == true)
    }

    @Test func announcerErrorsDoNotStopTheSession() {
        let h = Harness()
        h.announcer.prepareError = .unavailable
        h.announcer.speakError = .unavailable
        h.engine.start()
        #expect(h.engine.announcementError == .unavailable)
        h.advance(5)
        #expect(h.engine.phase == .running)
        h.advance(30)
        #expect(h.engine.phase == .finished(.completed))
        #expect(h.engine.announcementError == .unavailable)
    }

    @Test func announcementErrorClearsAfterSuccessfulSpeech() {
        let h = Harness(extras: [Self.item(10, "B"), Self.item(20, "C")])
        h.announcer.speakError = .unavailable
        h.announcer.speakErrorText = "B"
        h.startRunning()
        h.advance(10)
        #expect(h.engine.announcementError == .unavailable)
        h.advance(10)
        #expect(h.announcer.spoken.contains("C"))
        #expect(h.engine.announcementError == nil)
    }

    @Test func remainingFractionAndTimerDisplay() {
        let h = Harness()
        h.engine.start()
        #expect(h.engine.remainingFraction() == 1)
        h.advance(5)
        h.advance(15)
        #expect(h.engine.remainingFraction() == 0.5)
        #expect(!h.engine.timerDisplay.isPaused)
        h.engine.pause()
        #expect(h.engine.timerDisplay.isPaused)
        h.engine.resume()
        #expect(h.engine.timerDisplay.isPaused)
        h.advance(3)
        h.advance(15)
        #expect(h.engine.remainingFraction() == 0)
        #expect(h.engine.phase == .finished(.completed))
    }

    @Test func resumePassesSpokenOneOffsAndLastGapAnnouncement() throws {
        let h = Harness(extras: [
            Self.item(5, "H", kind: .halfway),
            Self.item(8, "F", kind: .filler)
        ])
        h.startRunning()
        h.advance(10)
        h.engine.pause()
        h.engine.resume()
        h.advance(3)
        let input = try #require(h.planner.planInputs.last)
        #expect(input.trigger == .resume)
        #expect(input.spokenOneOffs == [.halfway])
        #expect(input.lastGapAnnouncement == GapAnnouncement(second: 8, kind: .filler))
    }

    @Test func runReturnsImmediatelyWhenTerminal() async {
        let h = Harness()
        h.engine.start()
        h.engine.cancel()
        await h.engine.run()
        #expect(h.engine.phase == .cancelled)
    }

    @Test func runEndsWhenTaskIsCancelled() async {
        let h = Harness()
        h.engine.start()
        let engine = h.engine
        let task = Task { await engine.run() }
        task.cancel()
        await task.value
        #expect(!h.engine.phase.isTerminal)
    }
}
