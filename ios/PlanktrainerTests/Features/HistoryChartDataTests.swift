import Foundation
import Testing
@testable import Planktrainer

@Suite struct HistoryChartDataTests {
    private func session(daysAgo: Int, planned: Int = 60, achieved: Int = 60) -> PlankSession {
        PlankSession(
            startedAt: Date(timeIntervalSince1970: 1_000_000 - Double(daysAgo) * 86_400),
            plannedSeconds: planned,
            achievedSeconds: achieved
        )
    }

    @Test func emptyInputYieldsNoPoints() {
        #expect(HistoryChartData.points(from: []).isEmpty)
    }

    @Test func keepsNewest30OldestFirstWithSequentialIndices() {
        let sessions = (0..<35).map { session(daysAgo: $0) }
        let points = HistoryChartData.points(from: sessions)
        #expect(points.count == 30)
        #expect(points.map(\.index) == Array(0..<30))
        #expect(points.first?.startedAt == sessions[29].startedAtValue)
        #expect(points.last?.startedAt == sessions[0].startedAtValue)
        #expect(points.map(\.startedAt) == points.map(\.startedAt).sorted())
    }

    @Test func carriesGoalReachedAndSeconds() {
        let points = HistoryChartData.points(from: [
            session(daysAgo: 1, planned: 60, achieved: 45),
            session(daysAgo: 0, planned: 60, achieved: 75),
        ])
        #expect(points.map(\.isGoalReached) == [false, true])
        #expect(points.map(\.achievedSeconds) == [45, 75])
        #expect(points.map(\.plannedSeconds) == [60, 60])
    }
}
