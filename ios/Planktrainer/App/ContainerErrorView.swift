import SwiftUI

struct ContainerErrorView: View {
    let error: PersistenceError

    var body: some View {
        ContentUnavailableView {
            Label {
                Text("containerError.title", tableName: LocalizationTable.app.rawValue)
            } icon: {
                Image(systemName: "exclamationmark.triangle")
            }
        } description: {
            Text(verbatim: "\(error.localizedDescription)\n\n\(L10n.string("containerError.message", table: .app))")
        }
    }
}
