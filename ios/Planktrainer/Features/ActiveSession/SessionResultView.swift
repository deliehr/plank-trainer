import SwiftUI

struct SessionResultView: View {
    let result: SessionResult
    let onDone: () -> Void

    var body: some View {
        Text(verbatim: "SessionResultView") // PLACEHOLDER(W2-T5)
    }
}

#Preview {
    PreviewHost { SessionResultView(result: SessionResult(configuration: .standard, startedAt: .now, endedAt: .now, extensionSeconds: 0, achievedSeconds: 60, pauseCount: 0, outcome: .completed, isNewRecord: false), onDone: {}) }
}
