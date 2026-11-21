import SwiftUI

struct SessionTimerView: View {
    let display: SessionTimerDisplay
    let remainingFraction: () -> Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        timeline
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("display.remaining", tableName: LocalizationTable.sessionDisplay.rawValue))
            .accessibilityValue(accessibilityValue)
            .accessibilityAddTraits(.updatesFrequently)
    }

    @ViewBuilder
    private var timeline: some View {
        if reduceMotion {
            TimelineView(.periodic(from: .now, by: 1)) { _ in content }
        } else {
            TimelineView(.animation(paused: display.isPaused)) { _ in content }
        }
    }

    private var content: some View {
        VStack(spacing: ThemeSpacing.l) {
            ProgressRing(
                fraction: fraction,
                style: .session,
                isPaused: display.isPaused,
                isHighlighted: display.isFinalCountdown
            )
            .overlay { center }
            status
        }
    }

    private var fraction: Double {
        guard reduceMotion else { return remainingFraction() }
        guard display.totalSeconds > 0 else { return 0 }
        return Double(display.remainingSeconds) / Double(display.totalSeconds)
    }

    private var center: some View {
        VStack(spacing: ThemeSpacing.xs) {
            Text(verbatim: TimeText.clock(display.remainingSeconds))
                .scaledTimeFont(.session)
                .foregroundStyle(ThemeColor.contentPrimary)
            Text("display.elapsed \(TimeText.clock(display.elapsedSeconds))", tableName: LocalizationTable.sessionDisplay.rawValue)
                .font(ThemeFont.rowValue)
                .foregroundStyle(ThemeColor.contentSecondary)
        }
        .padding(ThemeSpacing.xl)
    }

    @ViewBuilder
    private var status: some View {
        if display.isPaused {
            Label {
                Text("display.paused", tableName: LocalizationTable.sessionDisplay.rawValue)
            } icon: {
                Image(systemName: "pause.circle.fill")
            }
            .font(ThemeFont.sessionCaption)
            .foregroundStyle(ThemeColor.paused)
        }
        if display.extensionSeconds > 0 {
            Text("display.extended \(TimeText.compactDuration(display.extensionSeconds))", tableName: LocalizationTable.sessionDisplay.rawValue)
                .font(ThemeFont.body)
                .foregroundStyle(ThemeColor.contentSecondary)
        }
    }

    private var accessibilityValue: String {
        let remaining = TimeText.accessibleDuration(display.remainingSeconds)
        guard display.isPaused else { return remaining }
        return [remaining, L10n.string("display.paused", table: .sessionDisplay)].joined(separator: ", ")
    }
}

#if DEBUG
private extension SessionTimerDisplay {
    static let running = SessionTimerDisplay(remainingSeconds: 30, elapsedSeconds: 30, totalSeconds: 60, extensionSeconds: 0, isPaused: false)
    static let pausedExtended = SessionTimerDisplay(remainingSeconds: 4, elapsedSeconds: 86, totalSeconds: 90, extensionSeconds: 30, isPaused: true)
}
#endif

#Preview {
    PreviewHost { SessionTimerView(display: .running, remainingFraction: { 0.5 }) }
}

#Preview("Paused extended") {
    PreviewHost { SessionTimerView(display: .pausedExtended, remainingFraction: { 0.05 }) }
}

#Preview("AX3") {
    PreviewHost { SessionTimerView(display: .pausedExtended, remainingFraction: { 0.05 }) }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { SessionTimerView(display: .running, remainingFraction: { 0.5 }) }
        .preferredColorScheme(.dark)
}
