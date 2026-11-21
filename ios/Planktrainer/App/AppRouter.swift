import Foundation
import Observation

enum AppTab: Hashable, CaseIterable, Sendable { case training, history, settings }

enum Route: Hashable, Sendable {
    case sessionDetail(UUID)
    case about
}

enum FullScreen: Identifiable, Hashable, Sendable {
    case activeSession(SessionConfiguration)
    var id: Self { self }
}

@Observable
final class AppRouter {
    var selectedTab: AppTab = .training
    var paths: [AppTab: [Route]] = [:]
    var fullScreen: FullScreen?

    /// Exactly one push level per tab (convention, enforced here).
    func push(_ route: Route) { paths[selectedTab] = [route] }
    func popToRoot() { paths[selectedTab] = [] }
    func present(_ fullScreen: FullScreen) { self.fullScreen = fullScreen }
    func dismissFullScreen() { fullScreen = nil }
    func path(for tab: AppTab) -> [Route] { paths[tab] ?? [] }
    func setPath(_ path: [Route], for tab: AppTab) { paths[tab] = Array(path.prefix(1)) }
}
