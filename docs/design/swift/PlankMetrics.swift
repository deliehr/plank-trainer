import SwiftUI

enum PlankSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    /// Session screen only: between major areas.
    static let session: CGFloat = 48
}

enum PlankRadius {
    static let chip: CGFloat = 8
    static let tile: CGFloat = 12
    /// Lists and cards use system shapes (inset grouped, ConcentricRectangle); this value is for custom containers only.
    static let card: CGFloat = 26
}

enum SessionControlMetrics {
    static let primaryHeight: CGFloat = 88
    static let secondaryHeight: CGFloat = 72
    static let cancelHeight: CGFloat = 48
    static let spacing: CGFloat = 16
    static let horizontalInset: CGFloat = 20
    /// Accessibility sizes: buttons stack vertically.
    static let accessibilityPrimaryHeight: CGFloat = 96
    static let accessibilitySecondaryHeight: CGFloat = 76
}

enum RingMetrics {
    // Session
    static let sessionDiameterRatio: CGFloat = 0.78
    static let sessionMaxDiameter: CGFloat = 340
    static let accessibilityDiameterRatio: CGFloat = 0.92
    static let strokeRatio: CGFloat = 0.075
    static let finalSecondsStrokeRatio: CGFloat = 0.09
    static let finalSecondsThreshold: TimeInterval = 5

    // Session detail
    static let detailDiameterRatio: CGFloat = 0.5
    static let detailStrokeRatio: CGFloat = 0.08

    // Mini (history, training header); no level mark
    static let miniDiameter: CGFloat = 28
    static let miniStroke: CGFloat = 4

    // Level mark: horizontal capsule centered on the track at 12 o'clock, color .primary
    static let levelMarkWidthRatio: CGFloat = 0.13
    static let levelMarkHeightRatio: CGFloat = 0.03

    // Paused: dashed arc, butt line caps
    static let pausedDashRatio: CGFloat = 0.6
    static let pausedGapRatio: CGFloat = 0.45

    // +10 s: added segment shown at reduced opacity, separated by a notch, merges after 1 s
    static let extensionSegmentOpacity: Double = 0.55
    static let extensionNotch: CGFloat = 2
    static let extensionHighlightDuration: TimeInterval = 1

    // New record: thin outer track around the completed ring
    static let recordTrackWidth: CGFloat = 3
    static let recordTrackGap: CGFloat = 6

    static func sessionDiameter(screenWidth: CGFloat, accessibilitySize: Bool) -> CGFloat {
        let ratio = accessibilitySize ? accessibilityDiameterRatio : sessionDiameterRatio
        return min(screenWidth * ratio, accessibilitySize ? .infinity : sessionMaxDiameter)
    }
}

enum PlankMotion {
    static let start = Animation.spring(duration: 0.4, bounce: 0)
    static let stateChange = Animation.easeInOut(duration: 0.25)
    static let extend = Animation.spring(duration: 0.45, bounce: 0.15)
    static let finalSecondsStroke = Animation.easeOut(duration: 0.3)
    static let finalSecondsPulseScale: CGFloat = 1.04
    static let completeColor = Animation.easeInOut(duration: 0.35)
    static let completeRipple = Animation.easeOut(duration: 0.6)
    static let completeRippleScale: CGFloat = 1.15
    static let completeRippleStartOpacity: Double = 0.5
    static let recordTrack = Animation.easeInOut(duration: 0.8)
    static let recordBadgeOffset: CGFloat = 12
    /// Used for every transition when "Reduce Motion" is on.
    static let reducedCrossfade = Animation.easeInOut(duration: 0.2)
    static let hintVisibleDuration: TimeInterval = 4
    static let extensionChipVisibleDuration: TimeInterval = 2
}
