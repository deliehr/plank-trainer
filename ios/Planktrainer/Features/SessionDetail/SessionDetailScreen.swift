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
    let session: PlankSession
    let summary: SessionHistorySummary
    let repeatSession: () -> Void

    private var dateText: String { TimeText.relativeDateTime(session.startedAtValue) }

    var body: some View {
        List {
            Section {
                ringHeader
                    .listRowBackground(Color.clear)
            }
            Section {
                LabeledContent {
                    Text(verbatim: dateText)
                } label: {
                    Text("detail.date", tableName: LocalizationTable.sessionDetail.rawValue)
                }
                statusRow
                durationRow("common.goal", table: LocalizationTable.common.rawValue, seconds: session.plannedSecondsValue, compact: false)
                durationRow("common.achieved", table: LocalizationTable.common.rawValue, seconds: session.achievedSecondsValue, compact: false)
                durationRow("detail.preparation", table: LocalizationTable.sessionDetail.rawValue, seconds: session.preparationSecondsValue)
                LabeledContent {
                    Text(verbatim: session.pauseCountValue.formatted())
                } label: {
                    Text("detail.pauses", tableName: LocalizationTable.sessionDetail.rawValue)
                }
                durationRow("detail.extension", table: LocalizationTable.sessionDetail.rawValue, seconds: session.extensionSecondsValue)
                recordGapRow
            }
            .font(ThemeFont.rowValue)
        }
        .navigationTitle(dateText)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: repeatSession) {
                Text("detail.repeat", tableName: LocalizationTable.sessionDetail.rawValue)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .padding(.horizontal, ThemeSpacing.l)
            .padding(.vertical, ThemeSpacing.s)
        }
    }

    private var ringHeader: some View {
        ZStack {
            ProgressRing(fraction: fraction, style: .detail)
            Text(verbatim: TimeText.clock(session.achievedSecondsValue))
                .scaledTimeFont(.detail)
                .padding(.horizontal, ThemeSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("detail.ring.label", tableName: LocalizationTable.sessionDetail.rawValue))
        .accessibilityValue(Text(verbatim: ringAccessibilityValue))
    }

    private var fraction: Double {
        min(1, Double(session.achievedSecondsValue) / Double(max(1, session.plannedSecondsValue)))
    }

    private var ringAccessibilityValue: String {
        let achieved = TimeText.accessibleDuration(session.achievedSecondsValue)
        let planned = TimeText.accessibleDuration(session.plannedSecondsValue)
        let progress = L10n.string("detail.ring.value \(achieved) \(planned)", table: .sessionDetail)
        let status = L10n.string(session.isGoalReached ? "common.goalReached" : "common.goalMissed", table: .common)
        return "\(progress), \(status)"
    }

    private var statusRow: some View {
        Group {
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
                    Image(systemName: "xmark.circle")
                }
                .foregroundStyle(ThemeColor.contentSecondary)
            }
        }
        .font(ThemeFont.body)
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

    @ViewBuilder
    private var recordGapRow: some View {
        if summary.isRecord(session) {
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
