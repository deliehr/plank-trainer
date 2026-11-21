import SwiftUI

struct SessionDetailScreen: View {
    let sessionID: UUID

    var body: some View {
        Text(verbatim: "SessionDetailScreen") // PLACEHOLDER(W2-T3)
    }
}

#Preview {
    PreviewHost { SessionDetailScreen(sessionID: UUID()) }
}
