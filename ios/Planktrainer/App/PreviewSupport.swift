#if DEBUG
import SwiftData
import SwiftUI

extension AppEnvironment {
    static func preview() -> AppEnvironment {
        AppEnvironment(
            userSettings: UserSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard),
            announcer: SilentAnnouncer()
        )
    }
}

enum PreviewData {
    private struct Sample {
        let daysAgo: Int
        let plannedSeconds: Int
        let achievedSeconds: Int
        let pauseCount: Int
    }

    private static let samples = [
        Sample(daysAgo: 0, plannedSeconds: 90, achievedSeconds: 90, pauseCount: 0),
        Sample(daysAgo: 1, plannedSeconds: 60, achievedSeconds: 45, pauseCount: 1),
        Sample(daysAgo: 2, plannedSeconds: 60, achievedSeconds: 60, pauseCount: 0),
        Sample(daysAgo: 4, plannedSeconds: 120, achievedSeconds: 150, pauseCount: 0),
        Sample(daysAgo: 5, plannedSeconds: 60, achievedSeconds: 30, pauseCount: 2),
        Sample(daysAgo: 7, plannedSeconds: 45, achievedSeconds: 45, pauseCount: 0),
        Sample(daysAgo: 8, plannedSeconds: 60, achievedSeconds: 50, pauseCount: 1),
        Sample(daysAgo: 10, plannedSeconds: 30, achievedSeconds: 30, pauseCount: 0),
    ]

    /// In-memory container with 8 sample sessions (mixed goal reached/missed, one clear record, dates over the last 10 days).
    static func makeContainer() throws -> ModelContainer {
        let container = try ModelContainerFactory.make(inMemory: true)
        let now = Date.now
        for sample in samples {
            let start = now.addingTimeInterval(-Double(sample.daysAgo) * 86_400)
            container.mainContext.insert(
                PlankSession(
                    startedAt: start,
                    endedAt: start.addingTimeInterval(Double(sample.achievedSeconds)),
                    preparationSeconds: 10,
                    plannedSeconds: sample.plannedSeconds,
                    extensionSeconds: max(0, sample.achievedSeconds - sample.plannedSeconds),
                    achievedSeconds: sample.achievedSeconds,
                    pauseCount: sample.pauseCount
                )
            )
        }
        return container
    }
}

/// Wraps preview content with container, AppEnvironment.preview() and a fresh AppRouter.
struct PreviewHost<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        do {
            let container = try PreviewData.makeContainer()
            return AnyView(
                content()
                    .environment(AppEnvironment.preview())
                    .environment(AppRouter())
                    .modelContainer(container)
            )
        } catch {
            return AnyView(ContainerErrorView(error: .containerCreationFailed(reason: error.localizedDescription)))
        }
    }
}
#endif
