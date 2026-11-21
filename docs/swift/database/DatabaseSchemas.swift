import Foundation
import SwiftData

let currentDatabaseSchema = DatabaseSchemaV1.schema

typealias MyEntity = DatabaseSchemaV1.MyEntity

enum DatabaseSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static let models: [any PersistentModel.Type] = [DatabaseSchemaV1.MyEntity.self]
    static var schema: Schema { Schema(models, version: versionIdentifier) }
}