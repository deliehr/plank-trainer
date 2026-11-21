import Foundation

enum PersistenceError: LocalizedError, Equatable {
    case containerCreationFailed(reason: String)

    var errorDescription: String? {
        L10n.string("error.persistence.containerFailed", table: .errors)
    }
}
