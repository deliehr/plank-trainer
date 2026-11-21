import Foundation
import Testing
@testable import Planktrainer

@Suite("AppRouter")
struct AppRouterTests {
    @Test func startsOnTrainingTab() {
        #expect(AppRouter().selectedTab == .training)
    }

    @Test func pushingTwiceKeepsSingleLevel() {
        let router = AppRouter()
        router.push(.about)
        router.push(.about)
        #expect(router.path(for: .training) == [.about])
    }

    @Test func pushAffectsOnlySelectedTab() {
        let router = AppRouter()
        router.selectedTab = .history
        router.push(.about)
        #expect(router.path(for: .history) == [.about])
        #expect(router.path(for: .training).isEmpty)
        #expect(router.path(for: .settings).isEmpty)
    }

    @Test func popToRootClearsOnlyCurrentTab() {
        let router = AppRouter()
        router.setPath([.about], for: .training)
        router.setPath([.about], for: .settings)
        router.selectedTab = .settings
        router.popToRoot()
        #expect(router.path(for: .settings).isEmpty)
        #expect(router.path(for: .training) == [.about])
    }

    @Test func setPathStoresOnlyFirstRoute() {
        let router = AppRouter()
        let id = UUID()
        router.setPath([.sessionDetail(id), .about], for: .history)
        #expect(router.path(for: .history) == [.sessionDetail(id)])
    }

    @Test func presentAndDismissFullScreen() {
        let router = AppRouter()
        router.present(.activeSession(.standard))
        #expect(router.fullScreen == .activeSession(.standard))
        router.dismissFullScreen()
        #expect(router.fullScreen == nil)
    }

    @Test func fullScreenIdentityIsItself() {
        let configuration = SessionConfiguration(plannedSeconds: 90, preparationSeconds: 15)
        #expect(FullScreen.activeSession(configuration).id == .activeSession(configuration))
    }
}
