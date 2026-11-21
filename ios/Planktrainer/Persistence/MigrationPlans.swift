import SwiftData

enum DatabaseMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [DatabaseSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
