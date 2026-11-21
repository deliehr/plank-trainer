import Foundation
import SwiftData

final class SessionStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func save(_ result: SessionResult) throws(SessionStoreError) -> PlankSession {
        let session = PlankSession(
            id: UUID(),
            startedAt: result.startedAt,
            endedAt: result.endedAt,
            preparationSeconds: result.configuration.preparationSeconds,
            plannedSeconds: result.configuration.plannedSeconds,
            extensionSeconds: result.extensionSeconds,
            achievedSeconds: result.achievedSeconds,
            pauseCount: result.pauseCount
        )
        context.insert(session)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw .saveFailed
        }
        return session
    }

    func delete(_ session: PlankSession) throws(SessionStoreError) {
        context.delete(session)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw .deleteFailed
        }
    }
}
