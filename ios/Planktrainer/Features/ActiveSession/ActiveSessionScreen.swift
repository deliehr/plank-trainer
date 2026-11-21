import SwiftUI

struct ActiveSessionScreen: View {
    let configuration: SessionConfiguration

    var body: some View {
        Text(verbatim: "ActiveSessionScreen") // PLACEHOLDER(W2-T4)
    }
}

#Preview {
    PreviewHost { ActiveSessionScreen(configuration: .standard) }
}
