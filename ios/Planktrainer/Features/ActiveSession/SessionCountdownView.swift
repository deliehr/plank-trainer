import SwiftUI

struct SessionCountdownDigit: View {
    let value: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(verbatim: "\(value)")
            .scaledTimeFont(.countdown)
            .foregroundStyle(ThemeColor.accent)
            .contentTransition(reduceMotion ? .identity : .numericText())
            .animation(reduceMotion ? nil : ThemeMotion.stateChange, value: value)
    }
}

extension View {
    func countdownAccessibility(caption: LocalizedStringResource, value: Int) -> some View {
        accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(caption))
            .accessibilityValue(Text("display.countdown.accessibility \(value)", tableName: LocalizationTable.sessionDisplay.rawValue))
            .accessibilityAddTraits(.updatesFrequently)
    }
}

struct SessionCountdownView: View {
    let value: Int
    let caption: LocalizedStringResource
    let detail: LocalizedStringResource

    var body: some View {
        VStack(spacing: ThemeSpacing.xl) {
            SessionCountdownDigit(value: value)
            VStack(spacing: ThemeSpacing.s) {
                Text(caption)
                    .font(ThemeFont.resultHeadline)
                    .foregroundStyle(ThemeColor.contentPrimary)
                Text(detail)
                    .font(ThemeFont.body)
                    .foregroundStyle(ThemeColor.contentSecondary)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, SessionControlMetrics.horizontalInset)
        .countdownAccessibility(caption: caption, value: value)
    }
}

struct SessionPostureHintView: View {
    var body: some View {
        VStack(spacing: ThemeSpacing.m) {
            Capsule()
                .fill(ThemeColor.contentSecondary)
                .frame(width: ThemeSpacing.session, height: ThemeSpacing.xs)
                .accessibilityHidden(true)
            Text(.activeSession("active.prepare.posture"))
                .font(ThemeFont.body)
                .foregroundStyle(ThemeColor.contentSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PreviewHost {
        SessionCountdownView(value: 7, caption: .activeSession("active.prepare.caption"), detail: .activeSession("active.prepare.goal \("1:30")"))
    }
}

#Preview("AX3") {
    PreviewHost {
        SessionCountdownView(value: 7, caption: .activeSession("active.prepare.caption"), detail: .activeSession("active.prepare.goal \("1:30")"))
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost {
        VStack {
            SessionCountdownView(value: 7, caption: .activeSession("active.prepare.caption"), detail: .activeSession("active.prepare.goal \("1:30")"))
            SessionPostureHintView().padding()
        }
    }
    .preferredColorScheme(.dark)
}
