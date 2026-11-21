import SwiftData

enum ModelContainerFactory {
    static func make(inMemory: Bool = false) throws(PersistenceError) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: currentDatabaseSchema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(
                for: currentDatabaseSchema,
                migrationPlan: DatabaseMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            throw .containerCreationFailed(reason: String(describing: error))
        }
    }
}
