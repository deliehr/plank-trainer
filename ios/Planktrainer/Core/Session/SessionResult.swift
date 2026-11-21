import Foundation

struct SessionResult: Equatable, Sendable {
    let configuration: SessionConfiguration
    let startedAt: Date
    let endedAt: Date
    let extensionSeconds: Int
    let achievedSeconds: Int
    let pauseCount: Int
    let outcome: SessionOutcome
    let isNewRecord: Bool

    var isGoalReached: Bool { achievedSeconds >= configuration.plannedSeconds }
}
