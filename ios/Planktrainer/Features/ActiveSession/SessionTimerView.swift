import SwiftUI

struct SessionTimerView: View {
    let display: SessionTimerDisplay
    let remainingFraction: () -> Double
    var coachLine: String?
    var resumeCountdown: Int?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var hasAppeared = false
    @State private var growthLag = 0.0
    @State private var highlightFraction = 0.0
    @State private var isExtensionChipVisible = false
    @State private var extensionPulse = 0

    var body: some View {
        VStack(spacing: ThemeSpacing.xl) {
            timeline
            captions
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(.updatesFrequently)
        .opacity(reduceMotion && !hasAppeared ? 0 : 1)
        .onAppear {
            withAnimation(reduceMotion ? ThemeMotion.reducedCrossfade : ThemeMotion.start) { hasAppeared = true }
        }
        .onChange(of: display.extensionSeconds) { oldValue, newValue in
            guard newValue > oldValue else { return }
            registerExtension(from: oldValue)
        }
        .task(id: extensionPulse) { await endExtensionHighlight() }
    }

    @ViewBuilder
    private var timeline: some View {
        if reduceMotion {
            TimelineView(.periodic(from: .now, by: 1)) { _ in ring }
        } else {
            TimelineView(.animation(paused: display.isPaused)) { _ in ring }
        }
    }

    private var fraction: Double {
        guard reduceMotion else { return remainingFraction() }
        guard display.totalSeconds > 0 else { return 0 }
        return Double(display.remainingSeconds) / Double(display.totalSeconds)
    }

    private var isFinalSeconds: Bool {
        !display.isPaused
            && display.remainingSeconds > 0
            && TimeInterval(display.remainingSeconds) <= RingMetrics.finalSecondsThreshold
    }

    private var ringState: RingState { display.isPaused ? .paused : .running }

    private var ring: some View {
        let current = fraction
        return SessionRing(
            fraction: current,
            fill: hasAppeared || reduceMotion ? 1 : 0,
            lag: growthLag,
            state: ringState,
            isFinalSeconds: isFinalSeconds,
            highlightFraction: highlightFraction,
            isDimmed: resumeCountdown != nil
        )
        .overlay {
            GeometryReader { proxy in
                center(fraction: current)
                    .frame(width: innerWidth(in: proxy.size.width))
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }

    private func innerWidth(in availableWidth: CGFloat) -> CGFloat {
        let diameter = RingMetrics.sessionDiameter(screenWidth: availableWidth, accessibilitySize: dynamicTypeSize.isAccessibilitySize)
        return diameter * (1 - 2 * RingMetrics.finalSecondsStrokeRatio) - 2 * ThemeSpacing.s
    }

    @ViewBuilder
    private func center(fraction: Double) -> some View {
        if let resumeCountdown {
            SessionCountdownDigit(value: resumeCountdown)
        } else {
            VStack(spacing: ThemeSpacing.xs) {
                Text(verbatim: TimeText.clock(display.remainingSeconds))
                    .scaledTimeFont(.session)
                    .foregroundStyle(ThemeColor.contentPrimary)
                    .scaleEffect(pulseScale(fraction: fraction))
                Text("display.of \(TimeText.clock(display.totalSeconds))", tableName: LocalizationTable.sessionDisplay.rawValue)
                    .font(ThemeFont.rowValue)
                    .foregroundStyle(ThemeColor.contentSecondary)
            }
            .overlay(alignment: .top) {
                let gap = ThemeSpacing.xs
                badge
                    .alignmentGuide(.top) { $0[.bottom] + gap }
            }
        }
    }

    @ViewBuilder
    private var badge: some View {
        if display.isPaused {
            Label {
                Text("display.paused", tableName: LocalizationTable.sessionDisplay.rawValue)
            } icon: {
                Image(systemName: "pause.fill")
            }
            .font(ThemeFont.sessionCaption)
            .foregroundStyle(ThemeColor.paused)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        } else if isExtensionChipVisible {
            Text(.activeSession("active.extend"))
                .font(ThemeFont.sectionTitle)
                .foregroundStyle(ThemeColor.accent)
                .padding(.horizontal, ThemeSpacing.m)
                .padding(.vertical, ThemeSpacing.xs)
                .background(ThemeColor.accent.opacity(ThemeOpacity.badgeFill), in: Capsule())
        }
    }

    private func pulseScale(fraction: Double) -> CGFloat {
        guard isFinalSeconds, !reduceMotion else { return 1 }
        let exactRemaining = fraction * Double(display.totalSeconds)
        let secondProgress = 1 - (exactRemaining - exactRemaining.rounded(.down))
        return 1 + (ThemeMotion.finalSecondsPulseScale - 1) * CGFloat(sin(.pi * secondProgress))
    }

    @ViewBuilder
    private var captions: some View {
        if resumeCountdown != nil {
            captionLines {
                Text(.activeSession("active.resuming.caption"))
                    .font(ThemeFont.sessionCaption)
                    .foregroundStyle(ThemeColor.contentSecondary)
                Text(.activeSession("active.resuming.hint"))
                    .font(ThemeFont.body)
                    .italic()
                    .foregroundStyle(ThemeColor.contentSecondary)
            }
        } else if !dynamicTypeSize.isAccessibilitySize {
            captionLines {
                Text("display.elapsed \(TimeText.clock(display.elapsedSeconds))", tableName: LocalizationTable.sessionDisplay.rawValue)
                    .font(ThemeFont.sessionCaption)
                    .foregroundStyle(ThemeColor.contentSecondary)
                    .monospacedDigit()
                secondaryLine
            }
        }
    }

    @ViewBuilder
    private var secondaryLine: some View {
        if display.isPaused {
            Text(.activeSession("active.announcementsPaused"))
                .font(ThemeFont.body)
                .italic()
                .foregroundStyle(ThemeColor.contentSecondary)
        } else if let coachLine {
            Text("active.coachLine \(coachLine)", tableName: LocalizationTable.activeSession.rawValue)
                .font(ThemeFont.body)
                .italic()
                .foregroundStyle(ThemeColor.contentSecondary)
        }
    }

    private func captionLines<Lines: View>(@ViewBuilder _ lines: () -> Lines) -> some View {
        VStack(spacing: ThemeSpacing.s) { lines() }
            .multilineTextAlignment(.center)
            .padding(.horizontal, SessionControlMetrics.horizontalInset)
    }

    private var accessibilityLabel: Text {
        if resumeCountdown != nil {
            return Text(.activeSession("active.resuming.caption"))
        }
        return Text("display.remaining", tableName: LocalizationTable.sessionDisplay.rawValue)
    }

    private var accessibilityValue: Text {
        if let resumeCountdown {
            return Text("display.countdown.accessibility \(resumeCountdown)", tableName: LocalizationTable.sessionDisplay.rawValue)
        }
        return Text(verbatim: SessionAccessibilityText.timerValue(display: display, coachLine: coachLine))
    }

    private func registerExtension(from previousExtension: Int) {
        let newTotal = Double(display.totalSeconds)
        let previousTotal = newTotal - Double(display.extensionSeconds - previousExtension)
        let newFraction = remainingFraction()
        let active = newTotal * (1 - newFraction)
        let previousFraction = previousTotal > 0 ? (previousTotal - active) / previousTotal : 0
        let delta = max(0, newFraction - previousFraction)

        isExtensionChipVisible = true
        extensionPulse += 1
        guard !display.isPaused, !reduceMotion else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            growthLag = delta
            highlightFraction = delta
        }
    }

    private func endExtensionHighlight() async {
        guard isExtensionChipVisible else { return }
        if growthLag > 0 {
            withAnimation(ThemeMotion.extend) { growthLag = 0 }
        }
        do {
            try await Task.sleep(for: .seconds(RingMetrics.extensionHighlightDuration))
            highlightFraction = 0
            try await Task.sleep(for: .seconds(ThemeMotion.extensionChipVisibleDuration - RingMetrics.extensionHighlightDuration))
        } catch {
            return
        }
        isExtensionChipVisible = false
    }
}

private struct SessionRing: View, Animatable {
    var fraction: Double
    var fill: Double
    var lag: Double
    let state: RingState
    let isFinalSeconds: Bool
    let highlightFraction: Double
    let isDimmed: Bool

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(fill, lag) }
        set {
            fill = newValue.first
            lag = newValue.second
        }
    }

    var body: some View {
        ProgressRing(
            fraction: max(0, fraction * fill - lag),
            style: .session,
            state: state,
            isFinalSeconds: isFinalSeconds,
            extensionHighlightFraction: highlightFraction,
            isDimmed: isDimmed
        )
    }
}

#if DEBUG
private extension SessionTimerDisplay {
    static let running = SessionTimerDisplay(remainingSeconds: 56, elapsedSeconds: 34, totalSeconds: 90, extensionSeconds: 0, isPaused: false)
    static let final = SessionTimerDisplay(remainingSeconds: 3, elapsedSeconds: 87, totalSeconds: 90, extensionSeconds: 0, isPaused: false)
    static let paused = SessionTimerDisplay(remainingSeconds: 56, elapsedSeconds: 34, totalSeconds: 90, extensionSeconds: 0, isPaused: true)
}

private let previewLine = "Das Sofa ruft. Ignorier es."
#endif

#Preview("Running") {
    PreviewHost { SessionTimerView(display: .running, remainingFraction: { 0.62 }, coachLine: previewLine) }
}

#Preview("Final seconds") {
    PreviewHost { SessionTimerView(display: .final, remainingFraction: { 0.033 }, coachLine: previewLine) }
}

#Preview("Paused") {
    PreviewHost { SessionTimerView(display: .paused, remainingFraction: { 0.62 }, coachLine: previewLine) }
}

#Preview("Resuming") {
    PreviewHost { SessionTimerView(display: .paused, remainingFraction: { 0.62 }, resumeCountdown: 2) }
}

#Preview("AX3") {
    PreviewHost { SessionTimerView(display: .running, remainingFraction: { 0.62 }, coachLine: previewLine) }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { SessionTimerView(display: .paused, remainingFraction: { 0.62 }, coachLine: previewLine) }
        .preferredColorScheme(.dark)
}
