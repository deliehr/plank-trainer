enum SessionOutcome: Equatable, Sendable { case completed, stopped }

enum SessionPhase: Equatable, Sendable {
    case preparing
    case running
    case paused
    case resuming
    case finished(SessionOutcome)
    case cancelled

    var isTerminal: Bool {
        switch self {
        case .finished, .cancelled: true
        case .preparing, .running, .paused, .resuming: false
        }
    }
}
