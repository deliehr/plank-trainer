import Foundation
import SwiftData

// MARK: - v1

extension DatabaseSchemaV1 {
    @Model
    final class PlankSession {
        var id: UUID?
        var startedAt: Date?
        var endedAt: Date?
        var preparationSeconds: Int?
        var plannedSeconds: Int?
        var extensionSeconds: Int?
        var achievedSeconds: Int?
        var pauseCount: Int?

        init(
            id: UUID? = UUID(),
            startedAt: Date? = nil,
            endedAt: Date? = nil,
            preparationSeconds: Int? = nil,
            plannedSeconds: Int? = nil,
            extensionSeconds: Int? = nil,
            achievedSeconds: Int? = nil,
            pauseCount: Int? = nil
        ) {
            self.id = id
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.preparationSeconds = preparationSeconds
            self.plannedSeconds = plannedSeconds
            self.extensionSeconds = extensionSeconds
            self.achievedSeconds = achievedSeconds
            self.pauseCount = pauseCount
        }
    }
}
