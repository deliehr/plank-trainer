import Observation

@Observable
final class AppEnvironment {
    let userSettings: UserSettings
    let announcer: any Announcing

    init(userSettings: UserSettings, announcer: any Announcing) {
        self.userSettings = userSettings
        self.announcer = announcer
    }
}
