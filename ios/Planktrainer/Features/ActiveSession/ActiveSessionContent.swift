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
    @State private var isConfirmingDiscard = false
    @State private var saveError: SessionStoreError?

    var body: some View {
        VStack(spacing: ThemeSpacing.l) {
            if !engine.phase.isTerminal {
                header
            }
            display
            SessionControlsView(engine: engine)
        }
        .padding(ThemeSpacing.l)
        .background(ThemeColor.surface.ignoresSafeArea())
        .task {
            engine.start()
            await engine.run()
        }
        .task {
            for await interruption in AudioInterruptionMonitor.interruptions() {
                if case .began = interruption { engine.pause() }
            }
        }
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
        VStack(spacing: ThemeSpacing.s) {
            Button(action: requestCancel) {
                Text(.activeSession("active.cancel"))
                    .frame(minHeight: ThemeSize.minimumTapTarget)
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity, alignment: .leading)
            if let error = engine.announcementError {
                AnnouncementNoticeView(error: error)
            }
        }
    }

    @ViewBuilder
    private var display: some View {
        switch engine.phase {
        case .preparing:
            SessionCountdownView(
                value: engine.preparationRemainingSeconds,
                caption: .activeSession("active.prepare.caption")
            )
        case .running, .paused:
            timer
        case .resuming:
            timer.overlay {
                SessionCountdownView(
                    value: engine.resumeCountdownRemainingSeconds,
                    caption: .activeSession("active.resuming.caption")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ThemeColor.surface.opacity(0.92))
            }
        case .finished:
            if let result = engine.result {
                SessionResultView(result: result, onDone: router.dismissFullScreen)
            }
        case .cancelled:
            Color.clear
        }
    }

    private var timer: some View {
        SessionTimerView(display: engine.timerDisplay, remainingFraction: { engine.remainingFraction() })
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
#Preview {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine()) }
}

#Preview("AX3") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine()) }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { ActiveSessionContent(engine: ActiveSessionPreview.engine()) }
        .preferredColorScheme(.dark)
}

enum ActiveSessionPreview {
    static func engine() -> SessionEngine {
        SessionEngine(
            configuration: .standard,
            history: SessionHistoryContext(recordSeconds: nil, lastSession: nil),
            coachStyle: .standard,
            postureHintsEnabled: true,
            announcer: SilentAnnouncer(),
            planner: AnnouncementPlanner(
                texts: AnnouncementTexts(),
                coach: PhraseSelector(locale: AppLocale.current, generator: SplitMix64(seed: 1))
            ),
            clock: SystemSessionClock()
        )
    }
}
#endif
