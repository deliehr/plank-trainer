import SwiftData
import SwiftUI
import UIKit

extension LocalizedStringResource {
    static func activeSession(_ key: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(key, table: LocalizationTable.activeSession.rawValue)
    }
}

struct ActiveSessionContent: View {
    let engine: SessionEngine

    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isConfirmingDiscard = false
    @State private var saveError: SessionStoreError?
    @State private var visibleNotice: AnnouncerError?
    @State private var noticeToken = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            stage
            bottomBar
        }
        .background(ThemeColor.sessionSurface.ignoresSafeArea())
        .overlay(alignment: .top) { notice }
        .task {
            engine.start()
            await engine.run()
        }
        .task {
            for await interruption in AudioInterruptionMonitor.interruptions() {
                if case .began = interruption { engine.pause() }
            }
        }
        .task(id: noticeToken) { await hideNoticeAfterDelay() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { engine.pause() }
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .sensoryFeedback(trigger: engine.hapticSignal) { _, signal in
            guard appEnvironment.userSettings.hapticsEnabled else { return nil }
            return signal?.haptic.feedback
        }
        .onChange(of: engine.phase) { _, phase in
            if phase.isTerminal { isConfirmingDiscard = false }
            if phase == .cancelled { router.dismissFullScreen() }
        }
        .onChange(of: engine.announcementError) { _, error in
            guard let error else { return }
            showNotice(error)
        }
        .onChange(of: engine.result) { _, result in
            guard let result else { return }
            save(result)
        }
        .confirmationDialog(
            Text(.activeSession("active.discard.title")),
            isPresented: $isConfirmingDiscard,
            titleVisibility: .visible
        ) {
            Button(role: .destructive, action: engine.cancel) {
                Text(.activeSession("active.discard.confirm"))
            }
            Button(role: .cancel) {} label: {
                Text(.activeSession("active.discard.keep"))
            }
        } message: {
            Text(.activeSession("active.discard.message"))
        }
        .alert(
            Text(.activeSession("active.saveError.title")),
            isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } }),
            presenting: saveError
        ) { _ in
            Button { } label: { Text(LocalizedStringResource("common.ok", table: LocalizationTable.common.rawValue)) }
        } message: { error in
            Text(verbatim: error.localizedDescription)
        }
    }

    private var header: some View {
        HStack {
            if !engine.phase.isTerminal {
                Button(action: requestCancel) {
                    Label { Text(.activeSession("active.cancel")) } icon: { Image(systemName: "xmark") }
                        .font(ThemeFont.sectionTitle)
                        .foregroundStyle(ThemeColor.contentPrimary)
                        .frame(minHeight: SessionControlMetrics.cancelHeight)
                }
                .buttonStyle(.glass)
                Spacer(minLength: ThemeSpacing.m)
                if showsCoachHint {
                    SessionCoachHintView(style: appEnvironment.userSettings.coachStyle)
                }
            } else {
                Color.clear.frame(height: SessionControlMetrics.cancelHeight)
            }
        }
        .padding(.horizontal, SessionControlMetrics.horizontalInset)
        .padding(.top, ThemeSpacing.m)
    }

    private var showsCoachHint: Bool {
        guard !dynamicTypeSize.isAccessibilitySize else { return false }
        return engine.phase == .running || engine.phase == .paused
    }

    private var stage: some View {
        GeometryReader { proxy in
            ScrollView {
                display
                    .frame(
                        maxWidth: .infinity,
                        minHeight: proxy.size.height,
                        alignment: engine.phase == .preparing ? .center : .top
                    )
                    .padding(.top, engine.phase == .preparing ? 0 : ThemeSpacing.session)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        Group {
            if engine.phase == .preparing {
                SessionPostureHintView()
            } else {
                SessionControlsView(engine: engine, onDone: router.dismissFullScreen)
            }
        }
        .padding(.horizontal, SessionControlMetrics.horizontalInset)
        .padding(.bottom, ThemeSpacing.s)
    }

    @ViewBuilder
    private var notice: some View {
        if let visibleNotice {
            AnnouncementNoticeView(error: visibleNotice)
                .padding(.top, SessionControlMetrics.cancelHeight + ThemeSpacing.xl)
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var display: some View {
        switch engine.phase {
        case .preparing:
            SessionCountdownView(
                value: engine.preparationRemainingSeconds,
                caption: .activeSession("active.prepare.caption"),
                detail: .activeSession("active.prepare.goal \(TimeText.clock(engine.configuration.plannedSeconds))")
            )
        case .running, .paused, .resuming:
            SessionTimerView(
                display: engine.timerDisplay,
                remainingFraction: { engine.remainingFraction() },
                coachLine: engine.latestCoachLine,
                resumeCountdown: engine.phase == .resuming ? engine.resumeCountdownRemainingSeconds : nil
            )
        case .finished:
            if let result = engine.result {
                SessionResultView(result: result, previousRecordSeconds: engine.previousRecordSeconds)
            }
        case .cancelled:
            Color.clear
        }
    }

    private func showNotice(_ error: AnnouncerError) {
        withAnimation(reduceMotion ? ThemeMotion.reducedCrossfade : ThemeMotion.stateChange) {
            visibleNotice = error
        }
        noticeToken += 1
    }

    private func hideNoticeAfterDelay() async {
        guard visibleNotice != nil else { return }
        do {
            try await Task.sleep(for: .seconds(ThemeMotion.hintVisibleDuration))
        } catch {
            return
        }
        withAnimation(reduceMotion ? ThemeMotion.reducedCrossfade : ThemeMotion.stateChange) {
            visibleNotice = nil
        }
    }

    private func requestCancel() {
        if engine.phase == .preparing {
            engine.cancel()
        } else {
            isConfirmingDiscard = true
        }
    }

    private func save(_ result: SessionResult) {
        do {
            try SessionStore(context: modelContext).save(result)
        } catch {
            saveError = error
        }
    }
}

#if DEBUG
#Preview("Preparing") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine(state: .preparing)) }
}

#Preview("Running") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine(state: .running)) }
}

#Preview("Paused") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine(state: .paused)) }
}

#Preview("Resuming") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine(state: .resuming)) }
}

#Preview("Record") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine(state: .finished(achieved: 105, record: 90))) }
}

#Preview("Missed") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine(state: .finished(achieved: 58, record: nil))) }
}

#Preview("AX3 running") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine(state: .running)) }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("AX3 record") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine(state: .finished(achieved: 105, record: 90))) }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark paused") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine(state: .paused)) }
        .preferredColorScheme(.dark)
}

#Preview("Dark running") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine(state: .running)) }
        .preferredColorScheme(.dark)
}

#Preview("Dark record") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine(state: .finished(achieved: 105, record: 90))) }
        .preferredColorScheme(.dark)
}

enum ActiveSessionPreview {
    enum State {
        case preparing, running, paused, resuming
        case finished(achieved: Int, record: Int?)
    }

    private final class SteppedClock: SessionClock {
        private let origin = ContinuousClock.now
        private var offset = Duration.zero

        var now: ContinuousClock.Instant { origin.advanced(by: offset) }
        var currentDate: Date { Date(timeIntervalSince1970: 1_700_000_000) }

        func advance(by duration: Duration) { offset += duration }
    }

    static func engine(state: State = .running) -> SessionEngine {
        let clock = SteppedClock()
        let record: Int?
        if case .finished(_, let previous) = state { record = previous } else { record = nil }
        let engine = SessionEngine(
            configuration: SessionConfiguration(plannedSeconds: 90, preparationSeconds: 10),
            history: SessionHistoryContext(recordSeconds: record, lastSession: nil),
            coachStyle: .cheeky,
            postureHintsEnabled: true,
            announcer: SilentAnnouncer(),
            planner: AnnouncementPlanner(
                texts: AnnouncementTexts(),
                coach: PhraseSelector(locale: AppLocale.current, generator: SplitMix64(seed: 1))
            ),
            clock: clock
        )
        engine.start()
        func advance(seconds: Int) {
            for _ in 0 ..< seconds * 10 {
                clock.advance(by: .milliseconds(100))
                engine.tick()
            }
        }
        switch state {
        case .preparing:
            advance(seconds: 3)
        case .running:
            advance(seconds: 10 + 34)
        case .paused:
            advance(seconds: 10 + 34)
            engine.pause()
        case .resuming:
            advance(seconds: 10 + 34)
            engine.pause()
            engine.resume()
            advance(seconds: 1)
        case .finished(let achieved, _):
            advance(seconds: 10)
            for _ in 0 ..< max(0, (achieved - 90 + 9) / 10) { engine.extend() }
            advance(seconds: achieved)
            engine.stop()
        }
        return engine
    }
}
#endif
