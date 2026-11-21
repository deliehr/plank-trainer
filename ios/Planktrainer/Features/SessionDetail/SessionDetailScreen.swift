import SwiftData
import SwiftUI

struct SessionDetailScreen: View {
    let sessionID: UUID

    @Query private var matches: [PlankSession]
    @Query private var allSessions: [PlankSession]
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(AppRouter.self) private var router

    init(sessionID: UUID) {
        self.sessionID = sessionID
        let id: UUID? = sessionID
        _matches = Query(filter: #Predicate<PlankSession> { $0.id == id })
    }

    var body: some View {
        if let session = matches.first {
            SessionDetailContent(
                session: session,
                summary: SessionHistorySummary(sessions: allSessions),
                repeatSession: { repeatSession(session) }
            )
        } else {
            ContentUnavailableView {
                Text("detail.notFound.title", tableName: LocalizationTable.sessionDetail.rawValue)
            }
        }
    }

    private func repeatSession(_ session: PlankSession) {
        appEnvironment.userSettings.rememberConfiguration(session.configuration)
        router.present(.activeSession(session.configuration))
    }
}

private struct SessionDetailContent: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let session: PlankSession
    let summary: SessionHistorySummary
    let repeatSession: () -> Void

    private var isRecord: Bool { summary.isRecord(session) }

    var body: some View {
        List {
            Section {
                ringHeader
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
            Section {
                LabeledContent {
                    Text(verbatim: SessionDetailFormatting.fullDate(session.startedAtValue))
                } label: {
                    Text("detail.date", tableName: LocalizationTable.sessionDetail.rawValue)
                }
                durationRow("common.goal", table: LocalizationTable.common.rawValue, seconds: session.plannedSecondsValue, compact: false)
                durationRow("common.achieved", table: LocalizationTable.common.rawValue, seconds: session.achievedSecondsValue, compact: false)
                durationRow("detail.preparation", table: LocalizationTable.sessionDetail.rawValue, seconds: session.preparationSecondsValue)
                pausesRow
                extensionRow
                recordGapRow
            }
            .font(ThemeFont.rowValue)
        }
        .navigationTitle(SessionDetailFormatting.title(for: session.startedAtValue))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: repeatSession) {
                Label {
                    Text("detail.repeat", tableName: LocalizationTable.sessionDetail.rawValue)
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .padding(.horizontal, ThemeSpacing.l)
            .padding(.vertical, ThemeSpacing.s)
        }
    }

    private var ringHeader: some View {
        VStack(spacing: ThemeSpacing.m) {
            ring
            statusLabel
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ThemeSpacing.m)
    }

    private var ring: some View {
        ZStack {
            ProgressRing(fraction: fraction, style: .detail, state: ringState)
            VStack(spacing: ThemeSpacing.xs) {
                Text(verbatim: TimeText.clock(session.achievedSecondsValue))
                    .scaledTimeFont(.detail)
                Text("detail.ring.of \(TimeText.clock(session.plannedSecondsValue))", tableName: LocalizationTable.sessionDetail.rawValue)
                    .font(ThemeFont.caption)
                    .foregroundStyle(ThemeColor.contentSecondary)
            }
            .padding(.horizontal, ThemeSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("detail.ring.label", tableName: LocalizationTable.sessionDetail.rawValue))
        .accessibilityValue(Text(verbatim: ringAccessibilityValue))
    }

    private var ringState: RingState {
        if isRecord { return .newRecord }
        return session.isGoalReached ? .completed : .running
    }

    private var fraction: Double {
        min(1, Double(session.achievedSecondsValue) / Double(max(1, session.plannedSecondsValue)))
    }

    private var ringAccessibilityValue: String {
        let achieved = TimeText.accessibleDuration(session.achievedSecondsValue)
        let planned = TimeText.accessibleDuration(session.plannedSecondsValue)
        return L10n.string("detail.ring.value \(achieved) \(planned)", table: .sessionDetail)
    }

    private var statusLabel: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: ThemeSpacing.s))
            : AnyLayout(HStackLayout(spacing: ThemeSpacing.l))
        return layout {
            if session.isGoalReached {
                Label {
                    Text("common.goalReached", tableName: LocalizationTable.common.rawValue)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .foregroundStyle(ThemeColor.success)
            } else {
                Label {
                    Text("common.goalMissed", tableName: LocalizationTable.common.rawValue)
                } icon: {
                    Image(systemName: "circle.lefthalf.filled")
                }
                .foregroundStyle(ThemeColor.contentSecondary)
            }
            if isRecord {
                Label {
                    Text("common.record", tableName: LocalizationTable.common.rawValue)
                } icon: {
                    Image(systemName: "trophy.fill")
                }
                .foregroundStyle(ThemeColor.accent)
            }
        }
        .font(ThemeFont.resultHeadline)
        .multilineTextAlignment(.center)
    }

    private func durationRow(
        _ key: LocalizedStringKey,
        table: String,
        seconds: Int,
        compact: Bool = true
    ) -> some View {
        LabeledContent {
            Text(verbatim: compact ? TimeText.compactDuration(seconds) : TimeText.clock(seconds))
        } label: {
            Text(key, tableName: table)
        }
    }

    private var pausesRow: some View {
        LabeledContent {
            if session.pauseCountValue == 0 {
                Text("detail.none", tableName: LocalizationTable.sessionDetail.rawValue)
            } else {
                Text(verbatim: session.pauseCountValue.formatted())
            }
        } label: {
            Text("detail.pauses", tableName: LocalizationTable.sessionDetail.rawValue)
        }
    }

    private var extensionRow: some View {
        LabeledContent {
            if session.extensionSecondsValue == 0 {
                Text("detail.none", tableName: LocalizationTable.sessionDetail.rawValue)
            } else {
                Text("detail.extension.added \(TimeText.compactDuration(session.extensionSecondsValue))", tableName: LocalizationTable.sessionDetail.rawValue)
            }
        } label: {
            Text("detail.extension", tableName: LocalizationTable.sessionDetail.rawValue)
        }
    }

    @ViewBuilder
    private var recordGapRow: some View {
        if isRecord {
            LabeledContent {
                Label {
                    Text("common.record", tableName: LocalizationTable.common.rawValue)
                } icon: {
                    Image(systemName: "trophy.fill")
                }
            } label: {
                Text("detail.recordGap", tableName: LocalizationTable.sessionDetail.rawValue)
            }
        } else if let gap = summary.secondsBelowRecord(session) {
            LabeledContent {
                Text("detail.recordGap.below \(TimeText.compactDuration(gap))", tableName: LocalizationTable.sessionDetail.rawValue)
            } label: {
                Text("detail.recordGap", tableName: LocalizationTable.sessionDetail.rawValue)
            }
        }
    }
}

#if DEBUG
private struct SampleSessionDetail: View {
    @Query(sort: \PlankSession.startedAt, order: .reverse) private var sessions: [PlankSession]

    var body: some View {
        NavigationStack {
            SessionDetailScreen(sessionID: sessions.dropFirst().first?.idValue ?? UUID())
        }
    }
}

#Preview {
    PreviewHost { SampleSessionDetail() }
}

#Preview("AX3") {
    PreviewHost { SampleSessionDetail() }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { SampleSessionDetail() }
        .preferredColorScheme(.dark)
}

#Preview("Not found") {
    PreviewHost { NavigationStack { SessionDetailScreen(sessionID: UUID()) } }
}
#endif
