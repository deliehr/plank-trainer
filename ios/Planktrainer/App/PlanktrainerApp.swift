import SwiftData
import SwiftUI

@main
struct PlanktrainerApp: App {
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
                Text(verbatim: "Planktrainer") // PLACEHOLDER(W0-T2)
                    .modelContainer(container)
            case .failure(let error):
                ContainerErrorView(error: error)
            }
        }
    }
}
