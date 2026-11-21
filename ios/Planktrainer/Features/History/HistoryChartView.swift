import Charts
import SwiftUI

struct HistoryChartView: View {
    let points: [HistoryChartPoint]
    let recordSeconds: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.s) {
            Text("history.chart.title", tableName: LocalizationTable.history.rawValue)
                .font(ThemeFont.sectionTitle)
                .accessibilityAddTraits(.isHeader)
            if let recordSeconds {
                Text("history.chart.summary \(TimeText.clock(recordSeconds))", tableName: LocalizationTable.history.rawValue)
                    .font(ThemeFont.caption)
                    .foregroundStyle(ThemeColor.contentSecondary)
            }
            chart
                .frame(height: ThemeSpacing.xxl * 6 + ThemeSpacing.l)
        }
        .padding(.vertical, ThemeSpacing.xs)
    }

    private var chart: some View {
        Chart {
            ForEach(points) { point in
                BarMark(
                    x: .value(axisSessionName, point.index),
                    y: .value(axisTimeName, point.achievedSeconds)
                )
                .foregroundStyle(point.isGoalReached ? ThemeColor.success : ThemeColor.contentSecondary)
                .annotation(position: .top) {
                    if point.isGoalReached {
                        Image(systemName: "checkmark")
                            .font(ThemeFont.caption)
                            .foregroundStyle(ThemeColor.success)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel(accessibilityDescription(for: point))
                .accessibilityValue(statusText(for: point))
            }
            if let recordSeconds {
                RuleMark(y: .value(axisTimeName, recordSeconds))
                    .foregroundStyle(ThemeColor.accent)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [ThemeSpacing.xs]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("common.record", tableName: LocalizationTable.common.rawValue)
                            .font(ThemeFont.caption)
                            .foregroundStyle(ThemeColor.accent)
                    }
                    .accessibilityLabel(L10n.string("common.record", table: .common))
                    .accessibilityValue(TimeText.accessibleDuration(recordSeconds))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let seconds = value.as(Int.self) {
                        Text(verbatim: TimeText.clock(seconds))
                    }
                }
            }
        }
    }

    private var axisSessionName: String { L10n.string("history.chart.axis.session", table: .history) }
    private var axisTimeName: String { L10n.string("history.chart.axis.time", table: .history) }

    private func accessibilityDescription(for point: HistoryChartPoint) -> String {
        L10n.string(
            "history.row.accessibility \(TimeText.relativeDateTime(point.startedAt)) \(TimeText.accessibleDuration(point.achievedSeconds)) \(TimeText.accessibleDuration(point.plannedSeconds))",
            table: .history
        )
    }

    private func statusText(for point: HistoryChartPoint) -> String {
        L10n.string(point.isGoalReached ? "common.goalReached" : "common.goalMissed", table: .common)
    }
}
