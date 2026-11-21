import SwiftUI

struct HistoryRow: View {
    let session: PlankSession
    let isRecord: Bool

    var body: some View {
        HStack(spacing: ThemeSpacing.m) {
            statusImage
            VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
                Text(
                    "history.row.result \(TimeText.clock(session.achievedSecondsValue)) \(TimeText.clock(session.plannedSecondsValue))",
                    tableName: LocalizationTable.history.rawValue
                )
                .font(ThemeFont.listTime)
                subtitle
                    .font(ThemeFont.caption)
            }
        }
        .frame(minHeight: ThemeSize.minimumTapTarget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var subtitle: Text {
        let date = Text(verbatim: HistoryDateText.sessionDate(session.startedAtValue))
            .foregroundStyle(ThemeColor.contentSecondary)
        guard isRecord else { return date }
        let separator = Text(verbatim: " · ").foregroundStyle(ThemeColor.accent)
        let trophy = Text(Image(systemName: "trophy.fill")).foregroundStyle(ThemeColor.accent)
        let label = Text("common.record", tableName: LocalizationTable.common.rawValue)
            .foregroundStyle(ThemeColor.accent)
        return Text("\(date)\(separator)\(trophy) \(label)")
    }

    private var statusImage: some View {
        Image(systemName: session.isGoalReached ? "checkmark.circle.fill" : "circle.lefthalf.filled")
            .font(.title2)
            .foregroundStyle(session.isGoalReached ? ThemeColor.success : ThemeColor.contentSecondary)
            .accessibilityLabel(statusText)
    }

    private var statusText: String {
        L10n.string(session.isGoalReached ? "common.goalReached" : "common.goalMissed", table: .common)
    }

    private var accessibilityLabel: String {
        let base = L10n.string(
            "history.row.accessibility \(HistoryDateText.sessionDate(session.startedAtValue)) \(TimeText.accessibleDuration(session.achievedSecondsValue)) \(TimeText.accessibleDuration(session.plannedSecondsValue))",
            table: .history
        )
        let parts = [base, statusText] + (isRecord ? [L10n.string("common.record", table: .common)] : [])
        return parts.joined(separator: ", ")
    }
}

#Preview {
    PreviewHost { HistoryRowPreviewList() }
}

#Preview("AX3") {
    PreviewHost { HistoryRowPreviewList() }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { HistoryRowPreviewList() }
        .preferredColorScheme(.dark)
}

private struct HistoryRowPreviewList: View {
    var body: some View {
        List {
            HistoryRow(session: PlankSession(startedAt: .now, plannedSeconds: 90, achievedSeconds: 90), isRecord: false)
            HistoryRow(session: PlankSession(startedAt: .now.addingTimeInterval(-86_400), plannedSeconds: 90, achievedSeconds: 58), isRecord: false)
            HistoryRow(session: PlankSession(startedAt: .now.addingTimeInterval(-400_000), plannedSeconds: 120, achievedSeconds: 135), isRecord: true)
        }
    }
}
