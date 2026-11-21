import SwiftUI

enum ThemeFont {
    static let sectionTitle: Font = .headline
    static let body: Font = .body
    static let caption: Font = .footnote
    static let valueEmphasis: Font = .title2.weight(.semibold).monospacedDigit()
    static let rowValue: Font = .body.monospacedDigit()
    static let sessionCaption: Font = .title2.weight(.semibold)
    static let resultHeadline: Font = .system(.title, design: .rounded, weight: .bold)
    static let recordValue: Font = .system(.title2, design: .rounded, weight: .semibold).monospacedDigit()
    static let sessionButton: Font = .system(.title3, design: .rounded, weight: .semibold)
    static let listTime: Font = .body.monospacedDigit()
    static let chartAxis: Font = .caption.monospacedDigit()
}

enum ScaledTimeSize: Sendable {
    case session
    case countdown
    case detail
    case result

    var baseSize: CGFloat {
        switch self {
        case .session: 96
        case .countdown: 160
        case .detail: 40
        case .result: 64
        }
    }

    var sizeRange: ClosedRange<CGFloat> {
        switch self {
        case .session: 72...150
        case .countdown: 120...200
        case .detail: 32...64
        case .result: 48...100
        }
    }

    var weight: Font.Weight {
        self == .countdown ? .bold : .semibold
    }

    var minimumScaleFactor: CGFloat {
        self == .session ? 0.6 : 0.4
    }
}

extension View {
    /// SF Pro Rounded with monospaced digits, scaled with Dynamic Type relative to .largeTitle
    /// and clamped to the size range of the given role; always one line.
    func scaledTimeFont(_ size: ScaledTimeSize) -> some View {
        modifier(ScaledTimeFontModifier(size: size))
    }
}

private struct ScaledTimeFontModifier: ViewModifier {
    let size: ScaledTimeSize
    @ScaledMetric(relativeTo: .largeTitle) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        let points = min(max(size.baseSize * scale, size.sizeRange.lowerBound), size.sizeRange.upperBound)
        content
            .font(.system(size: points, weight: size.weight, design: .rounded).monospacedDigit())
            .lineLimit(1)
            .minimumScaleFactor(size.minimumScaleFactor)
    }
}
