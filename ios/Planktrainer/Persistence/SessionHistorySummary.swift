import Foundation

struct SessionHistorySummary {
    let recordSeconds: Int?
    let recordSessionID: UUID?
    let lastSession: PlankSession?

    init(sessions: [PlankSession]) {
        let record = sessions
            .filter { $0.achievedSecondsValue > 0 }
            .reduce(nil as PlankSession?) { best, candidate in
                guard let best else { return candidate }
                if candidate.achievedSecondsValue != best.achievedSecondsValue {
                    return candidate.achievedSecondsValue > best.achievedSecondsValue ? candidate : best
                }
                return candidate.startedAtValue < best.startedAtValue ? candidate : best
            }
        recordSeconds = record?.achievedSecondsValue
        recordSessionID = record?.idValue
        lastSession = sessions.max { $0.startedAtValue < $1.startedAtValue }
    }

    var engineContext: SessionHistoryContext {
        SessionHistoryContext(
            recordSeconds: recordSeconds,
            lastSession: lastSession.map {
                LastSessionInfo(achievedSeconds: $0.achievedSecondsValue, isGoalReached: $0.isGoalReached)
            }
        )
    }

    func isRecord(_ session: PlankSession) -> Bool {
        recordSessionID == session.idValue
    }

    func secondsBelowRecord(_ session: PlankSession) -> Int? {
        guard let recordSeconds, !isRecord(session) else { return nil }
        return recordSeconds - session.achievedSecondsValue
    }
}
