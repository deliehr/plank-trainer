import SwiftUI

struct SessionCountdownView: View {
    let value: Int
    let caption: LocalizedStringResource

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: ThemeSpacing.m) {
            Text(verbatim: "\(value)")
                .scaledTimeFont(.countdown)
                .foregroundStyle(ThemeColor.contentPrimary)
                .contentTransition(reduceMotion ? .identity : .numericText())
            Text(caption)
                .font(ThemeFont.sessionCaption)
                .foregroundStyle(ThemeColor.contentSecondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(caption))
        .accessibilityValue(Text("display.countdown.accessibility \(value)", tableName: LocalizationTable.sessionDisplay.rawValue))
        .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    PreviewHost { SessionCountdownView(value: 3, caption: "Get ready") }
}

#Preview("AX3") {
    PreviewHost { SessionCountdownView(value: 3, caption: "Get ready") }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { SessionCountdownView(value: 3, caption: "Get ready") }
        .preferredColorScheme(.dark)
}
