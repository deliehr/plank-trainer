import SwiftData
import SwiftUI

struct TrainingScreen: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var sessions: [PlankSession]

    @State private var minutes: Int
    @State private var seconds: Int
    @State private var preparation: Int
    @State private var isPreparationExpanded = false
    @State private var hasLoadedStoredConfiguration = false

    private static let minutesRange = Array(0...10)
    private static let secondsRange = Array(stride(from: 0, through: 55, by: SessionConfiguration.stepSeconds))
    private static let preparationRange = Array(
        stride(
            from: SessionConfiguration.preparationSecondsRange.lowerBound,
            through: SessionConfiguration.preparationSecondsRange.upperBound,
            by: SessionConfiguration.stepSeconds
        )
    )

    init() {
        let standard = SessionConfiguration.standard
        _minutes = State(initialValue: standard.plannedSeconds / 60)
        _seconds = State(initialValue: standard.plannedSeconds % 60)
        _preparation = State(initialValue: standard.preparationSeconds)
    }

    private var userSettings: UserSettings { environment.userSettings }

    private var configuration: SessionConfiguration {
        SessionConfiguration(plannedSeconds: minutes * 60 + seconds, preparationSeconds: preparation)
    }

    var body: some View {
        Form {
            summarySection
            sessionTimeSection
            preparationSection
        }
        .navigationTitle(Text("training.title", tableName: LocalizationTable.training.rawValue))
        .safeAreaInset(edge: .bottom) { startButton }
        .onAppear(perform: loadStoredConfiguration)
        .onChange(of: minutes) { _, _ in normalize() }
        .onChange(of: seconds) { _, _ in normalize() }
        .onChange(of: preparation) { _, _ in normalize() }
    }

    private var summarySection: some View {
        let summary = SessionHistorySummary(sessions: sessions)
        return Section {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: ThemeSpacing.m))
                : AnyLayout(HStackLayout(spacing: ThemeSpacing.m))
            layout {
                ProgressRing(fraction: ringFraction(summary), style: .mini, state: ringState(summary))
                VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
                    if let record = summary.recordSeconds {
                        Text("training.summary.record \(TimeText.clock(record))", tableName: LocalizationTable.training.rawValue)
                            .font(ThemeFont.recordValue)
                        if let last = summary.lastSession {
                            lastSessionRow(last)
                        }
                    } else {
                        Text("training.summary.empty", tableName: LocalizationTable.training.rawValue)
                            .font(ThemeFont.recordValue)
                        Text("training.summary.emptyHint", tableName: LocalizationTable.training.rawValue)
                            .font(ThemeFont.body)
                            .foregroundStyle(ThemeColor.contentSecondary)
                    }
                }
            }
            .padding(.vertical, ThemeSpacing.xs)
        }
    }

    private func ringFraction(_ summary: SessionHistorySummary) -> Double {
        guard let record = summary.recordSeconds, record > 0, let last = summary.lastSession else { return 0 }
        return min(max(Double(last.achievedSecondsValue) / Double(record), 0), 1)
    }

    private func ringState(_ summary: SessionHistorySummary) -> RingState {
        summary.lastSession?.isGoalReached == true ? .completed : .running
    }

    private func lastSessionRow(_ session: PlankSession) -> some View {
        let reached = session.isGoalReached
        let date = TimeText.relativeDateTime(session.startedAtValue)
        let achieved = TimeText.clock(session.achievedSecondsValue)
        let status = reached
            ? Text("common.goalReached", tableName: LocalizationTable.common.rawValue)
            : Text("common.goalMissed", tableName: LocalizationTable.common.rawValue)
        return HStack(alignment: .firstTextBaseline, spacing: ThemeSpacing.xs) {
            Text("training.summary.last \(date) \(achieved)", tableName: LocalizationTable.training.rawValue)
            Image(systemName: reached ? "checkmark.circle.fill" : "circle.lefthalf.filled")
                .foregroundStyle(reached ? ThemeColor.success : ThemeColor.contentSecondary)
                .accessibilityLabel(status)
            if dynamicTypeSize.isAccessibilitySize {
                status
            }
        }
        .font(ThemeFont.rowValue)
        .foregroundStyle(ThemeColor.contentSecondary)
    }

    private var sessionTimeSection: some View {
        Section {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: ThemeSpacing.s))
                : AnyLayout(HStackLayout(spacing: ThemeSpacing.s))
            layout {
                wheel(selection: $minutes, values: Self.minutesRange, title: "training.minutes", unit: "training.minutes.unit")
                wheel(selection: $seconds, values: Self.secondsRange, title: "training.seconds", unit: "training.seconds.unit")
            }
        } header: {
            Text("training.sessionTime.header", tableName: LocalizationTable.training.rawValue)
        }
    }

    private func wheel(
        selection: Binding<Int>,
        values: [Int],
        title: LocalizedStringKey,
        unit: LocalizedStringKey
    ) -> some View {
        HStack(spacing: ThemeSpacing.xs) {
            Picker(selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(verbatim: "\(value)").tag(value)
                }
            } label: {
                Text(title, tableName: LocalizationTable.training.rawValue)
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            Text(unit, tableName: LocalizationTable.training.rawValue)
                .font(ThemeFont.body)
                .foregroundStyle(ThemeColor.contentSecondary)
                .accessibilityHidden(true)
        }
    }

    private var preparationSection: some View {
        Section {
            Button(action: togglePreparation) {
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: ThemeSpacing.xs))
                    : AnyLayout(HStackLayout())
                layout {
                    Text("training.preparation", tableName: LocalizationTable.training.rawValue)
                        .foregroundStyle(ThemeColor.contentPrimary)
                    if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                    HStack(spacing: ThemeSpacing.s) {
                        Text("training.preparation.value \(preparation)", tableName: LocalizationTable.training.rawValue)
                            .font(ThemeFont.rowValue)
                        Image(systemName: "chevron.right")
                            .font(ThemeFont.caption.weight(.semibold))
                            .rotationEffect(.degrees(isPreparationExpanded ? 90 : 0))
                            .animation(reduceMotion ? nil : ThemeMotion.stateChange, value: isPreparationExpanded)
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(isPreparationExpanded ? ThemeColor.accent : ThemeColor.contentSecondary)
                }
                .frame(minHeight: ThemeSize.minimumTapTarget)
                .contentShape(Rectangle())
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(Text("training.preparation.value \(preparation)", tableName: LocalizationTable.training.rawValue))
            .accessibilityAddTraits(isPreparationExpanded ? .isSelected : [])
            if isPreparationExpanded {
                Picker(selection: $preparation) {
                    ForEach(Self.preparationRange, id: \.self) { value in
                        Text("training.preparation.value \(value)", tableName: LocalizationTable.training.rawValue).tag(value)
                    }
                } label: {
                    Text("training.preparation", tableName: LocalizationTable.training.rawValue)
                }
                .pickerStyle(.wheel)
                .labelsHidden()
            }
        }
    }

    private var startButton: some View {
        Button(action: start) {
            Label {
                Text("training.start", tableName: LocalizationTable.training.rawValue)
            } icon: {
                Image(systemName: "play.fill")
            }
            .font(ThemeFont.sessionButton)
            .frame(maxWidth: .infinity, minHeight: startButtonHeight)
        }
        .buttonStyle(.glassProminent)
        .accessibilityHint(Text("training.start.hint", tableName: LocalizationTable.training.rawValue))
        .padding(.horizontal, ThemeSpacing.l)
        .padding(.vertical, ThemeSpacing.s)
    }

    private var startButtonHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? ThemeSize.startButtonAccessibilityHeight : ThemeSize.startButtonHeight
    }

    private func loadStoredConfiguration() {
        guard !hasLoadedStoredConfiguration else { return }
        hasLoadedStoredConfiguration = true
        let stored = userSettings.lastConfiguration
        minutes = stored.plannedSeconds / 60
        seconds = stored.plannedSeconds % 60
        preparation = stored.preparationSeconds
    }

    private func normalize() {
        let normalized = configuration
        let plannedSeconds = normalized.plannedSeconds
        if minutes != plannedSeconds / 60 { minutes = plannedSeconds / 60 }
        if seconds != plannedSeconds % 60 { seconds = plannedSeconds % 60 }
        if preparation != normalized.preparationSeconds { preparation = normalized.preparationSeconds }
    }

    private func togglePreparation() {
        withAnimation(reduceMotion ? ThemeMotion.reducedCrossfade : ThemeMotion.stateChange) {
            isPreparationExpanded.toggle()
        }
    }

    private func start() {
        let config = configuration
        userSettings.rememberConfiguration(config)
        router.present(.activeSession(config))
    }
}

#Preview {
    PreviewHost { TrainingScreen() }
}

#Preview("AX3") {
    PreviewHost { TrainingScreen() }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { TrainingScreen() }
        .preferredColorScheme(.dark)
}
