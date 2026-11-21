import SwiftUI

enum ThemeFont {
    static let sectionTitle: Font = .headline
    static let body: Font = .body
    static let caption: Font = .footnote
    static let valueEmphasis: Font = .title2.weight(.semibold).monospacedDigit()
    static let rowValue: Font = .body.monospacedDigit()
    static let sessionCaption: Font = .title2.weight(.semibold)
}

enum ScaledTimeSize: Sendable {
    case session
    case countdown
    case detail
    case result

    var baseSize: CGFloat {
        switch self {
        case .session: 88
        case .countdown: 120
        case .detail: 40
        case .result: 64
        }
    }
}

extension View {
    /// SF Pro Rounded, semibold, monospaced digits, scaled with Dynamic Type relative to .largeTitle,
    /// one line with minimumScaleFactor 0.4.
    func scaledTimeFont(_ size: ScaledTimeSize) -> some View {
        modifier(ScaledTimeFontModifier(size: size))
    }
}

private struct ScaledTimeFontModifier: ViewModifier {
    let size: ScaledTimeSize
    @ScaledMetric(relativeTo: .largeTitle) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .font(.system(size: size.baseSize * scale, weight: .semibold, design: .rounded).monospacedDigit())
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }
}
