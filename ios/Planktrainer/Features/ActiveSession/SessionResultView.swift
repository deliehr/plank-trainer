import SwiftUI

struct SessionResultView: View {
    let result: SessionResult
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounceTrigger = 0

    var body: some View {
        VStack(spacing: ThemeSpacing.xl) {
            Spacer(minLength: 0)
            VStack(spacing: ThemeSpacing.m) {
                Text(verbatim: TimeText.clock(result.achievedSeconds))
                    .scaledTimeFont(.result)
                    .foregroundStyle(ThemeColor.contentPrimary)
                Text("display.result.goal \(TimeText.clock(result.configuration.plannedSeconds))", tableName: LocalizationTable.sessionDisplay.rawValue)
                    .font(ThemeFont.sessionCaption)
                    .foregroundStyle(ThemeColor.contentSecondary)
                goalStatus
                if result.isNewRecord {
                    Label {
                        Text("common.newRecord", tableName: LocalizationTable.common.rawValue)
                    } icon: {
                        Image(systemName: "trophy.fill")
                    }
                    .font(ThemeFont.sessionCaption)
                    .foregroundStyle(ThemeColor.accent)
                }
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            Button(action: onDone) {
                Text("display.result.done", tableName: LocalizationTable.sessionDisplay.rawValue)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
        }
        .padding(ThemeSpacing.l)
        .task { if !reduceMotion { bounceTrigger += 1 } }
    }

    private var goalStatus: some View {
        let reached = result.isGoalReached
        return Label {
            Text(reached ? "common.goalReached" : "common.goalMissed", tableName: LocalizationTable.common.rawValue)
        } icon: {
            Image(systemName: reached ? "checkmark.circle.fill" : "xmark.circle")
                .symbolEffect(.bounce, value: bounceTrigger)
        }
        .font(ThemeFont.sessionCaption)
        .foregroundStyle(reached ? ThemeColor.success : ThemeColor.contentSecondary)
    }
}

#if DEBUG
private extension SessionResult {
    static func sample(achieved: Int, isNewRecord: Bool) -> SessionResult {
        SessionResult(configuration: .standard, startedAt: .now, endedAt: .now, extensionSeconds: 0, achievedSeconds: achieved, pauseCount: 0, outcome: .completed, isNewRecord: isNewRecord)
    }
}
#endif

#Preview {
    PreviewHost { SessionResultView(result: .sample(achieved: 60, isNewRecord: true), onDone: {}) }
}

#Preview("Missed") {
    PreviewHost { SessionResultView(result: .sample(achieved: 20, isNewRecord: false), onDone: {}) }
}

#Preview("AX3") {
    PreviewHost { SessionResultView(result: .sample(achieved: 60, isNewRecord: true), onDone: {}) }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { SessionResultView(result: .sample(achieved: 60, isNewRecord: true), onDone: {}) }
        .preferredColorScheme(.dark)
}
