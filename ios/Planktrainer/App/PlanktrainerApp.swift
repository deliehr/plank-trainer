import SwiftData
import SwiftUI

@main
struct PlanktrainerApp: App {
    @State private var appEnvironment = AppEnvironment(userSettings: UserSettings(), announcer: SpeechAnnouncer())
    @State private var router = AppRouter()
    private let containerResult: Result<ModelContainer, PersistenceError>

    init() {
        do {
            containerResult = .success(try ModelContainerFactory.make())
        } catch {
            containerResult = .failure(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch containerResult {
            case .success(let container):
                RootView()
                    .environment(appEnvironment)
                    .environment(router)
                    .preferredColorScheme(appEnvironment.userSettings.appearance.colorScheme)
                    .modelContainer(container)
            case .failure(let error):
                ContainerErrorView(error: error)
            }
        }
    }
}
