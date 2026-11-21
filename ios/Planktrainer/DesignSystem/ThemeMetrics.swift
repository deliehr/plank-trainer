import SwiftUI

enum ThemeSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let session: CGFloat = 48
}

enum ThemeRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 20
    static let chip: CGFloat = 8
    static let tile: CGFloat = 12
    static let card: CGFloat = 26
}

enum ThemeSize {
    static let minimumTapTarget: CGFloat = 44
    static let sessionControlHeight: CGFloat = 72
    static let sessionControlSpacing: CGFloat = 24
    static let startButtonHeight: CGFloat = 64
    static let startButtonAccessibilityHeight: CGFloat = 88
}

enum HistoryChartMetrics {
    static let missedBarOutlineWidth: CGFloat = 1.5
    static let recordRuleDash: [CGFloat] = [5, 4]
    static let recordRuleWidth: CGFloat = 1
}

enum ThemeOpacity {
    static let badgeFill: Double = 0.15
    static let extensionSegment: Double = 0.55
    static let dimmedRing: Double = 0.3
}

enum SessionControlMetrics {
    static let primaryHeight: CGFloat = 88
    static let secondaryHeight: CGFloat = 72
    static let cancelHeight: CGFloat = 48
    static let spacing: CGFloat = 16
    static let horizontalInset: CGFloat = 20
    static let accessibilityPrimaryHeight: CGFloat = 96
    static let accessibilitySecondaryHeight: CGFloat = 76
}

enum RingMetrics {
    static let sessionDiameterRatio: CGFloat = 0.78
    static let sessionMaxDiameter: CGFloat = 340
    static let accessibilityDiameterRatio: CGFloat = 0.92
    static let strokeRatio: CGFloat = 0.075
    static let finalSecondsStrokeRatio: CGFloat = 0.09
    static let finalSecondsThreshold: TimeInterval = 5

    static let detailDiameterRatio: CGFloat = 0.5
    static let detailStrokeRatio: CGFloat = 0.08

    static let miniDiameter: CGFloat = 28
    static let miniStroke: CGFloat = 4

    static let levelMarkWidthRatio: CGFloat = 0.13
    static let levelMarkHeightRatio: CGFloat = 0.03

    static let pausedDashRatio: CGFloat = 0.6
    static let pausedGapRatio: CGFloat = 0.45

    static let extensionSegmentOpacity: Double = ThemeOpacity.extensionSegment
    static let extensionNotch: CGFloat = 2
    static let extensionHighlightDuration: TimeInterval = 1

    static let recordTrackWidth: CGFloat = 3
    static let recordTrackGap: CGFloat = 6

    static let dimmedOpacity: Double = ThemeOpacity.dimmedRing

    // Existing names, kept for current call sites.
    static let compactDiameter: CGFloat = miniDiameter
    static let lineWidthRatio: CGFloat = strokeRatio

    static func sessionDiameter(screenWidth: CGFloat, accessibilitySize: Bool) -> CGFloat {
        if accessibilitySize { return screenWidth * accessibilityDiameterRatio }
        return min(screenWidth * sessionDiameterRatio, sessionMaxDiameter)
    }
}

enum ThemeMotion {
    static let start = Animation.spring(duration: 0.4, bounce: 0)
    static let stateChange = Animation.easeInOut(duration: 0.25)
    static let extend = Animation.spring(duration: 0.45, bounce: 0.15)
    static let finalSecondsStroke = Animation.easeOut(duration: 0.3)
    static let finalSecondsPulseScale: CGFloat = 1.04
    static let completeColor = Animation.easeInOut(duration: 0.35)
    static let completeRippleDuration: TimeInterval = 0.6
    static let completeRippleScale: CGFloat = 1.15
    static let completeRippleStartOpacity: Double = 0.5
    static let recordTrack = Animation.easeInOut(duration: 0.8).delay(0.4)
    static let recordBadgeOffset: CGFloat = 12
    static let reducedCrossfade = Animation.easeInOut(duration: 0.2)
    static let hintVisibleDuration: TimeInterval = 4
    static let extensionChipVisibleDuration: TimeInterval = 2
}
