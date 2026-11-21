import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            Tab(value: AppTab.training) {
                tabContent(for: .training) { TrainingScreen() }
            } label: {
                Label {
                    Text("tab.training", tableName: LocalizationTable.app.rawValue)
                } icon: {
                    Image(systemName: "figure.core.training")
                }
            }
            Tab(value: AppTab.history) {
                tabContent(for: .history) { HistoryScreen() }
            } label: {
                Label {
                    Text("tab.history", tableName: LocalizationTable.app.rawValue)
                } icon: {
                    Image(systemName: "chart.bar.fill")
                }
            }
            Tab(value: AppTab.settings) {
                tabContent(for: .settings) { SettingsScreen() }
            } label: {
                Label {
                    Text("tab.settings", tableName: LocalizationTable.app.rawValue)
                } icon: {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .fullScreenCover(item: $router.fullScreen) { fullScreen in
            switch fullScreen {
            case .activeSession(let configuration):
                ActiveSessionScreen(configuration: configuration)
            }
        }
    }

    private func tabContent<Content: View>(for tab: AppTab, @ViewBuilder root: () -> Content) -> some View {
        NavigationStack(
            path: Binding(
                get: { router.path(for: tab) },
                set: { router.setPath($0, for: tab) }
            )
        ) {
            root()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .sessionDetail(let id):
                        SessionDetailScreen(sessionID: id)
                    case .about:
                        AboutScreen()
                    }
                }
        }
    }
}
