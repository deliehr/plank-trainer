import SwiftUI

struct SessionTimerView: View {
    let display: SessionTimerDisplay
    let remainingFraction: () -> Double

    var body: some View {
        Text(verbatim: "SessionTimerView") // PLACEHOLDER(W2-T5)
    }
}

#Preview {
    PreviewHost { SessionTimerView(display: SessionTimerDisplay(remainingSeconds: 30, elapsedSeconds: 30, totalSeconds: 60, extensionSeconds: 0, isPaused: false), remainingFraction: { 0.5 }) }
}
