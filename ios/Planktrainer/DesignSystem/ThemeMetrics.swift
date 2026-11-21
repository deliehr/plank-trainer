import CoreGraphics

enum ThemeSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum ThemeRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 20
}

enum ThemeSize {
    static let minimumTapTarget: CGFloat = 44
    static let sessionControlHeight: CGFloat = 72
    static let sessionControlSpacing: CGFloat = 24
}

enum RingMetrics {
    static let sessionDiameterRatio: CGFloat = 0.78
    static let detailDiameterRatio: CGFloat = 0.5
    static let compactDiameter: CGFloat = 28
    static let lineWidthRatio: CGFloat = 0.08
}
