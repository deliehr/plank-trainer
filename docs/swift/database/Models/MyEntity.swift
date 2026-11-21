import SwiftData
import Foundation

// MARK: - v1

extension DatabaseSchemaV1 {
    @Model
    final class MyEntity {
        var name: String

        init(name: String
        ) {
            self.name = name
        }
    }
}

