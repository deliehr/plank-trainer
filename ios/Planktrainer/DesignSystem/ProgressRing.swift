import SwiftUI

enum RingState: Equatable, Sendable {
    case running, paused, completed, newRecord

    var isCompleted: Bool { self == .completed || self == .newRecord }
}

struct ProgressRing: View {
    enum Style: Sendable { case session, detail, mini }

    let fraction: Double
    var style: Style = .session
    var state: RingState = .running
    var isFinalSeconds: Bool = false
    var extensionHighlightFraction: Double = 0
    var isDimmed: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var rippleTrigger = 0

    var body: some View {
        GeometryReader { proxy in
            ring(diameter: diameter(availableWidth: proxy.size.width))
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(style == .mini ? nil : 1, contentMode: .fit)
        .frame(
            width: style == .mini ? RingMetrics.miniDiameter : nil,
            height: style == .mini ? RingMetrics.miniDiameter : nil
        )
        .opacity(isDimmed ? ThemeOpacity.dimmedRing : 1)
        .animation(reduceMotion ? ThemeMotion.reducedCrossfade : ThemeMotion.stateChange, value: isDimmed)
        .onChange(of: state) { oldState, newState in
            guard !reduceMotion, newState.isCompleted, !oldState.isCompleted else { return }
            rippleTrigger += 1
        }
        .accessibilityHidden(true)
    }

    private var arcColor: Color {
        switch state {
        case .running: ThemeColor.accent
        case .paused: ThemeColor.paused
        case .completed, .newRecord: ThemeColor.success
        }
    }

    private var visibleFraction: Double {
        state.isCompleted ? 1 : min(max(fraction, 0), 1)
    }

    private var trackOpacity: Double {
        RingTrackOpacity.value(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            highContrast: contrast == .increased
        )
    }

    private var stateAnimation: Animation {
        if reduceMotion { return ThemeMotion.reducedCrossfade }
        return state.isCompleted ? ThemeMotion.completeColor : ThemeMotion.stateChange
    }

    private func baseStroke(diameter: CGFloat) -> CGFloat {
        switch style {
        case .session: diameter * RingMetrics.strokeRatio
        case .detail: diameter * RingMetrics.detailStrokeRatio
        case .mini: RingMetrics.miniStroke
        }
    }

    private func diameter(availableWidth: CGFloat) -> CGFloat {
        switch style {
        case .session:
            RingMetrics.sessionDiameter(screenWidth: availableWidth, accessibilitySize: dynamicTypeSize.isAccessibilitySize)
        case .detail: availableWidth * RingMetrics.detailDiameterRatio
        case .mini: RingMetrics.miniDiameter
        }
    }

    private func ring(diameter: CGFloat) -> some View {
        let base = baseStroke(diameter: diameter)
        let width = isFinalSeconds && style == .session ? diameter * RingMetrics.finalSecondsStrokeRatio : base
        let pathDiameter = diameter - base
        let isPaused = state == .paused

        return ZStack {
            ZStack {
                Circle().stroke(arcColor.opacity(trackOpacity), lineWidth: width)
                solidArc(width: width, pathDiameter: pathDiameter)
                    .opacity(isPaused ? 0 : 1)
                dashedArc(width: width)
                    .opacity(isPaused ? 1 : 0)
            }
            .frame(width: pathDiameter, height: pathDiameter)
            .rotationEffect(.degrees(-90))
            .scaleEffect(x: -1)
            .animation(stateAnimation, value: state)
            .animation(reduceMotion ? ThemeMotion.reducedCrossfade : ThemeMotion.finalSecondsStroke, value: isFinalSeconds)

            ripple(width: width, pathDiameter: pathDiameter)
            recordTrack(diameter: diameter)
            if style != .mini { levelMark(diameter: diameter, pathDiameter: pathDiameter) }
        }
        .frame(width: diameter, height: diameter)
    }

    @ViewBuilder
    private func solidArc(width: CGFloat, pathDiameter: CGFloat) -> some View {
        let highlight = min(max(extensionHighlightFraction, 0), visibleFraction)
        let notch = RingMetrics.extensionNotch / (.pi * max(pathDiameter, 1))
        if highlight > notch && state == .running {
            let start = visibleFraction - highlight
            Circle().trim(from: 0, to: start)
                .stroke(arcColor, style: StrokeStyle(lineWidth: width, lineCap: .butt))
            Circle().trim(from: 0, to: 0.0001)
                .stroke(arcColor, style: StrokeStyle(lineWidth: width, lineCap: .round))
            Circle().trim(from: start + notch, to: visibleFraction)
                .stroke(
                    arcColor.opacity(ThemeOpacity.extensionSegment),
                    style: StrokeStyle(lineWidth: width, lineCap: .round)
                )
        } else {
            Circle().trim(from: 0, to: visibleFraction)
                .stroke(arcColor, style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
    }

    private func dashedArc(width: CGFloat) -> some View {
        Circle().trim(from: 0, to: visibleFraction)
            .stroke(
                arcColor,
                style: StrokeStyle(
                    lineWidth: width,
                    lineCap: .butt,
                    dash: [width * RingMetrics.pausedDashRatio, width * RingMetrics.pausedGapRatio]
                )
            )
    }

    private func levelMark(diameter: CGFloat, pathDiameter: CGFloat) -> some View {
        Capsule()
            .fill(ThemeColor.contentPrimary)
            .frame(
                width: diameter * RingMetrics.levelMarkWidthRatio,
                height: diameter * RingMetrics.levelMarkHeightRatio
            )
            .offset(y: -pathDiameter / 2)
    }

    private func recordTrack(diameter: CGFloat) -> some View {
        let trackDiameter = diameter + 2 * RingMetrics.recordTrackGap + RingMetrics.recordTrackWidth
        return Circle()
            .trim(from: 0, to: state == .newRecord ? 1 : 0)
            .stroke(
                ThemeColor.accent,
                style: StrokeStyle(lineWidth: RingMetrics.recordTrackWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .frame(width: trackDiameter, height: trackDiameter)
            .animation(reduceMotion ? nil : ThemeMotion.recordTrack, value: state)
    }

    private func ripple(width: CGFloat, pathDiameter: CGFloat) -> some View {
        Circle()
            .stroke(ThemeColor.success, lineWidth: width)
            .frame(width: pathDiameter, height: pathDiameter)
            .keyframeAnimator(initialValue: RippleValues(), trigger: rippleTrigger) { content, values in
                content.scaleEffect(values.scale).opacity(values.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(ThemeMotion.completeRippleScale, duration: ThemeMotion.completeRippleDuration)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(ThemeMotion.completeRippleStartOpacity, duration: 0.001)
                    CubicKeyframe(0, duration: ThemeMotion.completeRippleDuration)
                }
            }
    }
}

private struct RippleValues {
    var scale: CGFloat = 1
    var opacity: Double = 0
}

#Preview("Session", traits: .sizeThatFitsLayout) {
    RingPreviewGrid(style: .session)
}

#Preview("Detail", traits: .sizeThatFitsLayout) {
    RingPreviewGrid(style: .detail)
}

#Preview("Mini", traits: .sizeThatFitsLayout) {
    RingPreviewGrid(style: .mini)
}

private struct RingPreviewGrid: View {
    let style: ProgressRing.Style

    var body: some View {
        HStack(spacing: 0) {
            grid.environment(\.colorScheme, .light)
            grid.environment(\.colorScheme, .dark).background(Color.black)
        }
    }

    private var grid: some View {
        let width: CGFloat = style == .session ? 180 : 140
        return VStack(spacing: ThemeSpacing.xl) {
            ProgressRing(fraction: 0.6, style: style)
            ProgressRing(fraction: 0.1, style: style, isFinalSeconds: true)
            ProgressRing(fraction: 0.5, style: style, state: .paused)
            ProgressRing(fraction: 0.8, style: style, extensionHighlightFraction: 0.1)
            ProgressRing(fraction: 1, style: style, state: .completed)
            ProgressRing(fraction: 1, style: style, state: .newRecord)
        }
        .frame(width: width)
        .padding(ThemeSpacing.xxl)
    }
}
