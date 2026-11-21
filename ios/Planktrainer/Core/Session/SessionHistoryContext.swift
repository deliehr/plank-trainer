struct LastSessionInfo: Equatable, Sendable {
    let achievedSeconds: Int
    let isGoalReached: Bool
}

struct SessionHistoryContext: Equatable, Sendable {
    var recordSeconds: Int?
    var lastSession: LastSessionInfo?

    static let empty = SessionHistoryContext(recordSeconds: nil, lastSession: nil)
}
