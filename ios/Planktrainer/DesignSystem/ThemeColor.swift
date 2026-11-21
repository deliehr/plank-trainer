import SwiftUI

enum ThemeColor {
    static let accent: Color = .accentColor
    static let success = Color(.plankMoss)
    static let destructive = Color(.plankSignal)
    static let paused = Color(.plankAmber)
    static let sessionSurface = Color(.plankMatte)
    static let onAccent = Color(.plankOnIris)
    static let onSuccess = Color(.plankOnMoss)
    static let contentPrimary: Color = .primary
    static let contentSecondary: Color = .secondary
    static let surface = Color(uiColor: .systemBackground)
    static let groupedSurface = Color(uiColor: .systemGroupedBackground)
    static let elevatedSurface = Color(uiColor: .secondarySystemGroupedBackground)
    static let ringTrack = Color(uiColor: .tertiarySystemFill)
}

enum RingTrackOpacity {
    static let light: Double = 0.16
    static let dark: Double = 0.22
    static let reducedTransparency: Double = 0.30

    static func value(colorScheme: ColorScheme, reduceTransparency: Bool, highContrast: Bool) -> Double {
        if reduceTransparency || highContrast { return reducedTransparency }
        return colorScheme == .dark ? dark : light
    }
}
