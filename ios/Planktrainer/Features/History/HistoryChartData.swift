import Foundation

struct HistoryChartPoint: Identifiable, Equatable {
    let id: UUID
    let index: Int
    let achievedSeconds: Int
    let plannedSeconds: Int
    let isGoalReached: Bool
    let startedAt: Date
}

nonisolated enum HistoryChartData {
    static let maximumPoints = 30

    static func points(from sessions: [PlankSession]) -> [HistoryChartPoint] {
        sessions
            .sorted { $0.startedAtValue > $1.startedAtValue }
            .prefix(maximumPoints)
            .reversed()
            .enumerated()
            .map { index, session in
                HistoryChartPoint(
                    id: session.idValue,
                    index: index,
                    achievedSeconds: session.achievedSecondsValue,
                    plannedSeconds: session.plannedSecondsValue,
                    isGoalReached: session.isGoalReached,
                    startedAt: session.startedAtValue
                )
            }
    }

    static func averageSeconds(of points: [HistoryChartPoint]) -> Int? {
        guard !points.isEmpty else { return nil }
        let total = points.reduce(0) { $0 + $1.achievedSeconds }
        return Int((Double(total) / Double(points.count)).rounded())
    }
}
