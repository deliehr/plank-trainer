import Charts
import SwiftUI

struct HistoryChartView: View {
    let points: [HistoryChartPoint]
    let recordSeconds: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.m) {
            header
            chart
                .frame(height: HistoryChartMetrics.height)
            legend
        }
        .padding(.vertical, ThemeSpacing.xs)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("history.chart.title", tableName: LocalizationTable.history.rawValue)
                .font(ThemeFont.sectionTitle)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: ThemeSpacing.s)
            if let average = HistoryChartData.averageSeconds(of: points) {
                Text("history.chart.average \(TimeText.clock(average))", tableName: LocalizationTable.history.rawValue)
                    .font(ThemeFont.caption.monospacedDigit())
                    .foregroundStyle(ThemeColor.contentSecondary)
                    .accessibilityLabel(
                        L10n.string("history.chart.average \(TimeText.accessibleDuration(average))", table: .history)
                    )
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(points) { point in
                BarMark(
                    x: .value(axisSessionName, slot(point)),
                    y: .value(axisTimeName, point.achievedSeconds),
                    width: .ratio(HistoryChartMetrics.barWidthRatio)
                )
                .foregroundStyle(point.isGoalReached ? ThemeColor.success : Color.clear)
                .accessibilityLabel(accessibilityDescription(for: point))
                .accessibilityValue(statusText(for: point))
            }
            if let recordSeconds {
                RuleMark(y: .value(axisTimeName, recordSeconds))
                    .foregroundStyle(ThemeColor.contentPrimary)
                    .lineStyle(StrokeStyle(lineWidth: HistoryChartMetrics.recordRuleWidth, dash: HistoryChartMetrics.recordRuleDash))
                    .annotation(position: .trailing, alignment: .center) {
                        Text(verbatim: TimeText.clock(recordSeconds))
                            .font(ThemeFont.chartAxis.weight(.semibold))
                            .foregroundStyle(ThemeColor.contentPrimary)
                    }
                    .accessibilityLabel(L10n.string("common.record", table: .common))
                    .accessibilityValue(TimeText.accessibleDuration(recordSeconds))
            }
        }
        .chartXAxis(.hidden)
        .chartXScale(domain: points.map(slot))
        .chartYScale(domain: 0...yAxisMaximum)
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let seconds = value.as(Int.self) {
                        Text(verbatim: seconds == 0 ? "0" : TimeText.clock(seconds))
                            .font(ThemeFont.chartAxis)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let plotAnchor = proxy.plotFrame {
                    missedBarOutlines(proxy: proxy, plotFrame: geometry[plotAnchor])
                }
            }
            .accessibilityHidden(true)
        }
    }

    private func slot(_ point: HistoryChartPoint) -> String {
        String(point.index)
    }

    private func missedBarOutlines(proxy: ChartProxy, plotFrame: CGRect) -> some View {
        let slotWidth = plotFrame.width / CGFloat(max(points.count, 1))
        let barWidth = slotWidth * HistoryChartMetrics.barWidthRatio
        return ForEach(points.filter { !$0.isGoalReached }) { point in
            if let centerX = proxy.position(forX: slot(point)),
               let top = proxy.position(forY: point.achievedSeconds),
               let bottom = proxy.position(forY: 0) {
                Rectangle()
                    .strokeBorder(ThemeColor.contentSecondary, lineWidth: HistoryChartMetrics.missedBarOutlineWidth)
                    .frame(width: barWidth, height: max(bottom - top, HistoryChartMetrics.missedBarOutlineWidth * 2))
                    .position(x: plotFrame.minX + centerX, y: plotFrame.minY + (top + bottom) / 2)
            }
        }
    }

    private var yAxisMaximum: Int {
        max(recordSeconds ?? 0, points.map(\.achievedSeconds).max() ?? 0, 1)
    }

    private var legend: some View {
        HStack(spacing: ThemeSpacing.l) {
            legendItem(text: Text("history.chart.legend.reached", tableName: LocalizationTable.history.rawValue)) {
                Image(systemName: "square.fill").foregroundStyle(ThemeColor.success)
            }
            legendItem(text: Text("history.chart.legend.missed", tableName: LocalizationTable.history.rawValue)) {
                Image(systemName: "square").foregroundStyle(ThemeColor.contentSecondary)
            }
            legendItem(text: Text("common.record", tableName: LocalizationTable.common.rawValue)) {
                RecordLegendLine()
            }
        }
        .font(ThemeFont.caption)
        .foregroundStyle(ThemeColor.contentSecondary)
        .accessibilityHidden(true)
    }

    private func legendItem(text: Text, @ViewBuilder symbol: () -> some View) -> some View {
        HStack(spacing: ThemeSpacing.xs) {
            symbol()
            text
        }
    }

    private var axisSessionName: String { L10n.string("history.chart.axis.session", table: .history) }
    private var axisTimeName: String { L10n.string("history.chart.axis.time", table: .history) }

    private func accessibilityDescription(for point: HistoryChartPoint) -> String {
        L10n.string(
            "history.row.accessibility \(HistoryDateText.sessionDate(point.startedAt)) \(TimeText.accessibleDuration(point.achievedSeconds)) \(TimeText.accessibleDuration(point.plannedSeconds))",
            table: .history
        )
    }

    private func statusText(for point: HistoryChartPoint) -> String {
        L10n.string(point.isGoalReached ? "common.goalReached" : "common.goalMissed", table: .common)
    }
}

private struct RecordLegendLine: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: ThemeSpacing.xs))
            path.addLine(to: CGPoint(x: ThemeSpacing.l, y: ThemeSpacing.xs))
        }
        .stroke(
            ThemeColor.contentPrimary,
            style: StrokeStyle(lineWidth: HistoryChartMetrics.recordRuleWidth, dash: HistoryChartMetrics.recordRuleDash)
        )
        .frame(width: ThemeSpacing.l, height: ThemeSpacing.s)
    }
}

#Preview {
    PreviewHost { HistoryChartPreview() }
}

#Preview("AX3") {
    PreviewHost { HistoryChartPreview() }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { HistoryChartPreview() }
        .preferredColorScheme(.dark)
}

private struct HistoryChartPreview: View {
    private let points = (0..<20).map { index in
        HistoryChartPoint(
            id: UUID(),
            index: index,
            achievedSeconds: 40 + (index * 7) % 80,
            plannedSeconds: 90,
            isGoalReached: index % 3 != 0,
            startedAt: .now.addingTimeInterval(Double(index - 20) * 86_400)
        )
    }

    var body: some View {
        List {
            Section { HistoryChartView(points: points, recordSeconds: 135) }
        }
    }
}
