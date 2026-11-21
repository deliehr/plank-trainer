import SwiftUI
import UIKit

/// Brand color tokens. Text, lists and forms keep using system colors
/// (`.primary`, `.secondary`, `systemBackground`, `systemGroupedBackground`).
/// Custom colors exist only where they carry meaning: ring, status, session surface.
extension Color {
    /// Session screen surface only. Everywhere else: system backgrounds.
    static let plankMatte = Color(light: 0xF5F3FC, dark: 0x0B0A12, highContrastLight: 0xFFFFFF, highContrastDark: 0x000000)

    /// Accent: running ring, primary actions, app tint.
    static let plankIris = Color(light: 0x5B3FD9, dark: 0xA496FF, highContrastLight: 0x3F25B8, highContrastDark: 0xC2B8FF)

    /// Foreground on `plankIris` fills (buttons).
    static let plankOnIris = Color(light: 0xFFFFFF, dark: 0x0B0A12, highContrastLight: 0xFFFFFF, highContrastDark: 0x000000)

    /// Success: goal reached.
    static let plankMoss = Color(light: 0x1E7F45, dark: 0x3DD67A, highContrastLight: 0x136434, highContrastDark: 0x6BEA9E)

    /// Foreground on `plankMoss` fills (status badges).
    static let plankOnMoss = Color(light: 0xFFFFFF, dark: 0x0B0A12, highContrastLight: 0xFFFFFF, highContrastDark: 0x000000)

    /// Paused state.
    static let plankAmber = Color(light: 0x9A5B00, dark: 0xFFB547, highContrastLight: 0x7A4700, highContrastDark: 0xFFCB7A)

    /// Destructive only (discard, delete). Use with `role: .destructive`.
    static let plankSignal = Color(light: 0xC8261B, dark: 0xFF6B61, highContrastLight: 0xB0170C, highContrastDark: 0xFF9890)
}

extension Color {
    init(light: UInt32, dark: UInt32, highContrastLight: UInt32, highContrastDark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let isHighContrast = traits.accessibilityContrast == .high
            switch (isDark, isHighContrast) {
            case (false, false): return UIColor(hex: light)
            case (true, false): return UIColor(hex: dark)
            case (false, true): return UIColor(hex: highContrastLight)
            case (true, true): return UIColor(hex: highContrastDark)
            }
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Track opacity behind the ring arc.
enum RingTrackOpacity {
    static let light: Double = 0.16
    static let dark: Double = 0.22
    /// "Reduce Transparency" or "Increase Contrast" enabled.
    static let reducedTransparency: Double = 0.30

    static func value(colorScheme: ColorScheme, reduceTransparency: Bool, highContrast: Bool) -> Double {
        if reduceTransparency || highContrast { return reducedTransparency }
        return colorScheme == .dark ? dark : light
    }
}
