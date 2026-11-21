import Foundation
import SwiftData

let currentDatabaseSchema = DatabaseSchemaV1.schema

typealias PlankSession = DatabaseSchemaV1.PlankSession

enum DatabaseSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static let models: [any PersistentModel.Type] = [DatabaseSchemaV1.PlankSession.self]
    static var schema: Schema { Schema(models, version: versionIdentifier) }
}
