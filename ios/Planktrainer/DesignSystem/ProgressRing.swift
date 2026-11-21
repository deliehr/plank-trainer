import SwiftUI

struct ProgressRing: View {
    enum Style: Sendable { case session, detail, compact }

    let fraction: Double
    var style: Style = .session
    var isPaused: Bool = false
    var isHighlighted: Bool = false

    private static let highlightedLineWidthFactor: CGFloat = 1.15
    private static let pausedDashRatio: CGFloat = 0.6
    private static let pausedGapRatio: CGFloat = 1.6

    var body: some View {
        GeometryReader { proxy in
            let diameter = diameter(availableWidth: proxy.size.width)
            ring(diameter: diameter)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(style == .compact ? nil : 1, contentMode: .fit)
        .frame(
            width: style == .compact ? RingMetrics.compactDiameter : nil,
            height: style == .compact ? RingMetrics.compactDiameter : nil
        )
        .accessibilityHidden(true)
    }

    private func ring(diameter: CGFloat) -> some View {
        let baseLineWidth = diameter * RingMetrics.lineWidthRatio
        let lineWidth = isHighlighted ? baseLineWidth * Self.highlightedLineWidthFactor : baseLineWidth
        let inset = baseLineWidth * Self.highlightedLineWidthFactor / 2

        return ZStack {
            Circle()
                .inset(by: inset)
                .stroke(ThemeColor.ringTrack, lineWidth: baseLineWidth)
            Circle()
                .inset(by: inset)
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(
                    isPaused ? ThemeColor.paused : ThemeColor.accent,
                    style: strokeStyle(lineWidth: lineWidth)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: diameter, height: diameter)
    }

    private func strokeStyle(lineWidth: CGFloat) -> StrokeStyle {
        guard isPaused else {
            return StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        }
        return StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .round,
            dash: [lineWidth * Self.pausedDashRatio, lineWidth * Self.pausedGapRatio]
        )
    }

    private func diameter(availableWidth: CGFloat) -> CGFloat {
        switch style {
        case .session: availableWidth * RingMetrics.sessionDiameterRatio
        case .detail: availableWidth * RingMetrics.detailDiameterRatio
        case .compact: RingMetrics.compactDiameter
        }
    }
}

#Preview("Fractions") {
    VStack(spacing: ThemeSpacing.xl) {
        ProgressRing(fraction: 1.0, style: .detail)
        ProgressRing(fraction: 0.5, style: .detail)
        ProgressRing(fraction: 0.1, style: .detail)
        ProgressRing(fraction: 0.5, style: .compact)
    }
    .padding(ThemeSpacing.l)
}

#Preview("Paused and highlighted") {
    HStack(spacing: ThemeSpacing.xl) {
        ProgressRing(fraction: 0.5, style: .detail, isPaused: true)
        ProgressRing(fraction: 0.9, style: .detail, isHighlighted: true)
    }
    .padding(ThemeSpacing.l)
}

#Preview("Dark") {
    ProgressRing(fraction: 0.5, style: .session, isPaused: true)
        .padding(ThemeSpacing.l)
        .preferredColorScheme(.dark)
}
