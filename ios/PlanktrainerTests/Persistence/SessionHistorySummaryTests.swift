import Foundation
import SwiftData
import Testing
@testable import Planktrainer

@Suite struct SessionHistorySummaryTests {
    private func session(start: TimeInterval, achieved: Int, planned: Int = 60) -> PlankSession {
        PlankSession(
            startedAt: Date(timeIntervalSince1970: start),
            plannedSeconds: planned,
            achievedSeconds: achieved
        )
    }

    @Test func emptyListHasNoRecordAndNoLastSession() {
        let summary = SessionHistorySummary(sessions: [])
        #expect(summary.recordSeconds == nil)
        #expect(summary.recordSessionID == nil)
        #expect(summary.lastSession == nil)
        #expect(summary.engineContext == .empty)
    }

    @Test func recordIsMaximumAchievedSeconds() {
        let best = session(start: 200, achieved: 90)
        let summary = SessionHistorySummary(sessions: [session(start: 100, achieved: 40), best, session(start: 300, achieved: 70)])
        #expect(summary.recordSeconds == 90)
        #expect(summary.recordSessionID == best.idValue)
    }

    @Test func tieGoesToEarliestSession() {
        let earliest = session(start: 100, achieved: 80)
        let later = session(start: 200, achieved: 80)
        for input in [[earliest, later], [later, earliest]] {
            let summary = SessionHistorySummary(sessions: input)
            #expect(summary.recordSessionID == earliest.idValue)
            #expect(summary.isRecord(earliest))
            #expect(!summary.isRecord(later))
        }
    }

    @Test func zeroSecondSessionsProduceNoRecord() {
        let summary = SessionHistorySummary(sessions: [session(start: 100, achieved: 0), session(start: 200, achieved: 0)])
        #expect(summary.recordSeconds == nil)
        #expect(summary.recordSessionID == nil)
        #expect(summary.lastSession != nil)
    }

    @Test func lastSessionIsIndependentOfInputOrder() {
        let old = session(start: 100, achieved: 50)
        let mid = session(start: 200, achieved: 50)
        let new = session(start: 300, achieved: 50)
        for input in [[old, mid, new], [new, old, mid], [mid, new, old]] {
            #expect(SessionHistorySummary(sessions: input).lastSession?.idValue == new.idValue)
        }
    }

    @Test func engineContextReflectsGoalReached() {
        let reached = SessionHistorySummary(sessions: [session(start: 100, achieved: 70, planned: 60)])
        #expect(reached.engineContext == SessionHistoryContext(
            recordSeconds: 70, lastSession: LastSessionInfo(achievedSeconds: 70, isGoalReached: true)
        ))

        let missed = SessionHistorySummary(sessions: [session(start: 100, achieved: 40, planned: 60)])
        #expect(missed.engineContext.lastSession == LastSessionInfo(achievedSeconds: 40, isGoalReached: false))
    }

    @Test func secondsBelowRecord() {
        let record = session(start: 100, achieved: 90)
        let below = session(start: 200, achieved: 78)
        let tied = session(start: 300, achieved: 90)
        let summary = SessionHistorySummary(sessions: [record, below, tied])
        #expect(summary.secondsBelowRecord(below) == 12)
        #expect(summary.secondsBelowRecord(record) == nil)
        #expect(summary.secondsBelowRecord(tied) == 0)
    }

    @Test func secondsBelowRecordIsNilWithoutRecord() {
        let empty = session(start: 100, achieved: 0)
        #expect(SessionHistorySummary(sessions: [empty]).secondsBelowRecord(empty) == nil)
    }

    @Test func recordIsRecomputedAfterDeletingRecordSession() throws {
        let container = try ModelContainerFactory.make(inMemory: true)
        let context = container.mainContext
        let store = SessionStore(context: context)
        let weaker = try store.save(result(achieved: 50, start: 100))
        let record = try store.save(result(achieved: 90, start: 200))

        #expect(SessionHistorySummary(sessions: try context.fetch(FetchDescriptor<PlankSession>())).recordSeconds == 90)

        try store.delete(record)
        let summary = SessionHistorySummary(sessions: try context.fetch(FetchDescriptor<PlankSession>()))
        #expect(summary.recordSeconds == 50)
        #expect(summary.recordSessionID == weaker.idValue)
    }

    private func result(achieved: Int, start: TimeInterval) -> SessionResult {
        SessionResult(
            configuration: .standard,
            startedAt: Date(timeIntervalSince1970: start),
            endedAt: Date(timeIntervalSince1970: start + 100),
            extensionSeconds: 0,
            achievedSeconds: achieved,
            pauseCount: 0,
            outcome: .completed,
            isNewRecord: false
        )
    }
}
