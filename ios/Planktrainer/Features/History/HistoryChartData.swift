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
}
