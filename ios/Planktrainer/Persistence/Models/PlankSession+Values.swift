import Foundation

extension PlankSession {
    static let missingID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

    var idValue: UUID { id ?? Self.missingID }
    var startedAtValue: Date { startedAt ?? .distantPast }
    var endedAtValue: Date { endedAt ?? startedAtValue }
    var preparationSecondsValue: Int { preparationSeconds ?? SessionConfiguration.standard.preparationSeconds }
    var plannedSecondsValue: Int { plannedSeconds ?? SessionConfiguration.standard.plannedSeconds }
    var extensionSecondsValue: Int { extensionSeconds ?? 0 }
    var achievedSecondsValue: Int { achievedSeconds ?? 0 }
    var pauseCountValue: Int { pauseCount ?? 0 }
    var isGoalReached: Bool { achievedSecondsValue >= plannedSecondsValue }
    var configuration: SessionConfiguration {
        SessionConfiguration(plannedSeconds: plannedSecondsValue, preparationSeconds: preparationSecondsValue)
    }
}
