import SwiftUI

struct SessionCountdownView: View {
    let value: Int
    let caption: LocalizedStringResource

    var body: some View {
        Text(verbatim: "SessionCountdownView") // PLACEHOLDER(W2-T5)
    }
}

#Preview {
    PreviewHost { SessionCountdownView(value: 3, caption: "Placeholder") }
}
