import Foundation
import SwiftData

extension iOSApp {
    static var sharedModelContainer: ModelContainer = {
        createModelContainer(isStoredInMemoryOnly: false)
    }()

    static var previewModelContainer: ModelContainer = {
        let previewContainer = createModelContainer(isStoredInMemoryOnly: true)
        
        let context = previewContainer.mainContext
        
        // example data
        
        context.trySave()
        
        return previewContainer
    }()
    
    private static func createModelContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        let schema = currentDatabaseSchema
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)

        do {
            let container = try ModelContainer(for: schema, migrationPlan: DatabaseMigrationPlan.self, configurations: [modelConfiguration])
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}