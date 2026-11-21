import SwiftUI

extension Font {
    /// Result headline, e.g. "Geschafft".
    static let plankResultHeadline = Font.system(.title, design: .rounded, weight: .bold)
    /// Record value and detail values, e.g. "Rekord 2:15".
    static let plankRecordValue = Font.system(.title2, design: .rounded, weight: .semibold).monospacedDigit()
    /// Labels of the large session buttons.
    static let plankSessionButton = Font.system(.title3, design: .rounded, weight: .semibold)
    /// Times in lists, e.g. "1:30 / 1:30".
    static let plankListTime = Font.body.monospacedDigit()
    /// Chart axis labels.
    static let plankChartAxis = Font.caption.monospacedDigit()
}

/// Remaining time inside the session ring. 96 pt at default size, scales with Dynamic Type, clamped to 72–150 pt.
struct SessionTimeFont: ViewModifier {
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 96

    func body(content: Content) -> some View {
        content
            .font(.system(size: min(max(size, 72), 150), weight: .semibold, design: .rounded).monospacedDigit())
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

/// Preparation and resume countdown digit. 160 pt at default size, clamped to 120–200 pt.
struct CountdownFont: ViewModifier {
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 160

    func body(content: Content) -> some View {
        content
            .font(.system(size: min(max(size, 120), 200), weight: .bold, design: .rounded).monospacedDigit())
            .lineLimit(1)
    }
}

extension View {
    func sessionTimeFont() -> some View { modifier(SessionTimeFont()) }
    func countdownFont() -> some View { modifier(CountdownFont()) }
}
