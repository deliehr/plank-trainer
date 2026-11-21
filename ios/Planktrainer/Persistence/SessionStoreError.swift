import Foundation

enum SessionStoreError: LocalizedError, Equatable {
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed: L10n.string("error.store.saveFailed", table: .errors)
        case .deleteFailed: L10n.string("error.store.deleteFailed", table: .errors)
        }
    }
}
