import SwiftData
import SwiftUI

struct ActiveSessionScreen: View {
    let configuration: SessionConfiguration

    @Environment(AppEnvironment.self) private var appEnvironment
    @Query private var sessions: [PlankSession]
    @State private var engine: SessionEngine?

    var body: some View {
        ZStack {
            ThemeColor.sessionSurface.ignoresSafeArea()
            if let engine {
                ActiveSessionContent(engine: engine)
            }
        }
        .onAppear {
            if engine == nil { engine = makeEngine() }
        }
    }

    private func makeEngine() -> SessionEngine {
        let settings = appEnvironment.userSettings
        let locale = AppLocale.current
        return SessionEngine(
            configuration: configuration,
            history: SessionHistorySummary(sessions: sessions).engineContext,
            coachStyle: settings.coachStyle,
            postureHintsEnabled: settings.postureHintsEnabled,
            announcer: appEnvironment.announcer,
            planner: AnnouncementPlanner(
                texts: AnnouncementTexts(locale: locale),
                coach: PhraseSelector(locale: locale, generator: SplitMix64(seed: UInt64.random(in: .min ... .max)))
            ),
            clock: SystemSessionClock()
        )
    }
}

#Preview {
    PreviewHost { ActiveSessionScreen(configuration: .standard) }
}

#Preview("AX3") {
    PreviewHost { ActiveSessionScreen(configuration: .standard) }
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Dark") {
    PreviewHost { ActiveSessionScreen(configuration: .standard) }
        .preferredColorScheme(.dark)
}
