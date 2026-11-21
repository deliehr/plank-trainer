import SwiftData
import Foundation

enum DatabaseMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [DatabaseSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []
    }
}

