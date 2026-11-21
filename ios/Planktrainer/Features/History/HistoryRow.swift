import SwiftUI

struct HistoryRow: View {
    let session: PlankSession
    let isRecord: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        layout {
            Text(verbatim: TimeText.relativeDateTime(session.startedAtValue))
                .font(ThemeFont.body)
            Spacer(minLength: ThemeSpacing.s)
            HStack(spacing: ThemeSpacing.s) {
                if isRecord {
                    Label {
                        Text("common.record", tableName: LocalizationTable.common.rawValue)
                    } icon: {
                        Image(systemName: "trophy.fill")
                    }
                    .font(ThemeFont.caption)
                    .foregroundStyle(ThemeColor.accent)
                }
                Text(
                    "history.row.result \(TimeText.clock(session.achievedSecondsValue)) \(TimeText.clock(session.plannedSecondsValue))",
                    tableName: LocalizationTable.history.rawValue
                )
                .font(ThemeFont.rowValue)
                statusImage
            }
        }
        .frame(minHeight: ThemeSize.minimumTapTarget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: ThemeSpacing.xs))
            : AnyLayout(HStackLayout(spacing: ThemeSpacing.s))
    }

    private var statusImage: some View {
        Image(systemName: session.isGoalReached ? "checkmark.circle.fill" : "xmark.circle")
            .foregroundStyle(session.isGoalReached ? ThemeColor.success : ThemeColor.contentSecondary)
    }

    private var accessibilityLabel: String {
        let base = L10n.string(
            "history.row.accessibility \(TimeText.relativeDateTime(session.startedAtValue)) \(TimeText.accessibleDuration(session.achievedSecondsValue)) \(TimeText.accessibleDuration(session.plannedSecondsValue))",
            table: .history
        )
        let status = L10n.string(session.isGoalReached ? "common.goalReached" : "common.goalMissed", table: .common)
        let parts = [base, status] + (isRecord ? [L10n.string("common.record", table: .common)] : [])
        return parts.joined(separator: ", ")
    }
}
