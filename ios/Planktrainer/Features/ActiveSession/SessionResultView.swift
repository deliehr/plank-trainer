import SwiftUI

struct SessionResultView: View {
    let result: SessionResult
    let previousRecordSeconds: Int?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var ringState = RingState.running
    @State private var isCheckmarkDrawn = false
    @State private var isBadgeShown = false

    private var isGoalReached: Bool { result.isGoalReached }

    private var finalRingState: RingState {
        guard isGoalReached else { return .running }
        return result.isNewRecord ? .newRecord : .completed
    }

    private var ringFraction: Double {
        guard !isGoalReached, result.configuration.plannedSeconds > 0 else { return 1 }
        return Double(result.achievedSeconds) / Double(result.configuration.plannedSeconds)
    }

    var body: some View {
        VStack(spacing: ThemeSpacing.xl) {
            ProgressRing(fraction: ringFraction, style: .session, state: ringState)
                .overlay {
                    GeometryReader { proxy in
                        center
                            .frame(width: innerWidth(in: proxy.size.width))
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                }
            summary
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: SessionAccessibilityText.resultLabel(result: result, previousRecordSeconds: previousRecordSeconds)))
        .task { await reveal() }
    }

    private func innerWidth(in availableWidth: CGFloat) -> CGFloat {
        let diameter = RingMetrics.sessionDiameter(screenWidth: availableWidth, accessibilitySize: dynamicTypeSize.isAccessibilitySize)
        return diameter * (1 - 2 * RingMetrics.strokeRatio) - 2 * ThemeSpacing.s
    }

    private var center: some View {
        VStack(spacing: ThemeSpacing.xs) {
            if isGoalReached {
                Image(systemName: "checkmark")
                    .font(ThemeFont.resultHeadline)
                    .foregroundStyle(ThemeColor.success)
                    .symbolEffect(.drawOn, isActive: !isCheckmarkDrawn)
            }
            Text(verbatim: TimeText.clock(result.achievedSeconds))
                .scaledTimeFont(.result)
                .foregroundStyle(ThemeColor.contentPrimary)
            Text(goalCaption)
                .font(ThemeFont.rowValue)
                .foregroundStyle(ThemeColor.contentSecondary)
        }
    }

    private var goalCaption: LocalizedStringResource {
        let planned = TimeText.clock(result.configuration.plannedSeconds)
        return isGoalReached
            ? .sessionDisplay("display.result.goal \(planned)")
            : .sessionDisplay("display.of \(planned)")
    }

    private var summary: some View {
        VStack(spacing: ThemeSpacing.s) {
            Text(isGoalReached ? .sessionDisplay("display.result.headline.reached") : .sessionDisplay("display.result.headline.missed"))
                .font(ThemeFont.resultHeadline)
                .foregroundStyle(ThemeColor.contentPrimary)
            if !isGoalReached {
                line(.sessionDisplay("display.result.remainingToGoal \(result.configuration.plannedSeconds - result.achievedSeconds)"))
            }
            if result.isNewRecord, let previousRecordSeconds {
                line(.sessionDisplay("display.result.overRecord \(result.achievedSeconds - previousRecordSeconds) \(TimeText.clock(previousRecordSeconds))"))
            }
            if result.isNewRecord {
                recordBadge
            }
            if !isGoalReached {
                line(.sessionDisplay("display.result.saved")).italic()
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, SessionControlMetrics.horizontalInset)
    }

    private func line(_ text: LocalizedStringResource) -> Text {
        Text(text)
            .font(ThemeFont.body)
            .foregroundStyle(ThemeColor.contentSecondary)
    }

    private var recordBadge: some View {
        Label {
            Text("common.newRecord", tableName: LocalizationTable.common.rawValue)
        } icon: {
            Image(systemName: "trophy.fill")
        }
        .font(ThemeFont.sectionTitle)
        .foregroundStyle(ThemeColor.accent)
        .padding(.horizontal, ThemeSpacing.l)
        .padding(.vertical, ThemeSpacing.s)
        .background(ThemeColor.accent.opacity(ThemeOpacity.badgeFill), in: Capsule())
        .padding(.top, ThemeSpacing.xs)
        .opacity(isBadgeShown ? 1 : 0)
        .offset(y: isBadgeShown ? 0 : ThemeMotion.recordBadgeOffset)
        .animation(reduceMotion ? nil : ThemeMotion.recordTrack, value: isBadgeShown)
    }

    private func reveal() async {
        await Task.yield()
        withAnimation(reduceMotion ? ThemeMotion.reducedCrossfade : nil) {
            ringState = finalRingState
        }
        isCheckmarkDrawn = true
        isBadgeShown = true
    }
}

#if DEBUG
private extension SessionResult {
    static func sample(achieved: Int, planned: Int = 90, isNewRecord: Bool) -> SessionResult {
        SessionResult(
            configuration: SessionConfiguration(plannedSeconds: planned, preparationSeconds: 10),
            startedAt: .now,
            endedAt: .now,
            extensionSeconds: 0,
            achievedSeconds: achieved,
            pauseCount: 0,
            outcome: .completed,
            isNewRecord: isNewRecord
        )
    }
}
#endif

#Preview("Record") {
    PreviewHost { SessionResultView(result: .sample(achieved: 105, isNewRecord: true), previousRecordSeconds: 90) }
}

#Preview("Completed") {
    PreviewHost { SessionResultView(result: .sample(achieved: 90, isNewRecord: false), previousRecordSeconds: 120) }
}

#Preview("Missed") {
    PreviewHost { SessionResultView(result: .sample(achieved: 58, isNewRecord: false), previousRecordSeconds: 120) }
}

#Preview("AX3") {
    PreviewHost { SessionResultView(result: .sample(achieved: 105, isNewRecord: true), previousRecordSeconds: 90) }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { SessionResultView(result: .sample(achieved: 105, isNewRecord: true), previousRecordSeconds: 90) }
        .preferredColorScheme(.dark)
}

#Preview("Dark missed") {
    PreviewHost { SessionResultView(result: .sample(achieved: 58, isNewRecord: false), previousRecordSeconds: 120) }
        .preferredColorScheme(.dark)
}
