import Foundation
import Testing
@testable import Planktrainer

@Suite("UserSettings")
struct UserSettingsTests {
    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)"))
    }

    @Test func defaultsOnEmptySuite() throws {
        let settings = UserSettings(defaults: try makeDefaults())
        #expect(settings.appearance == .system)
        #expect(settings.coachStyle == .demanding)
        #expect(settings.postureHintsEnabled)
        #expect(settings.hapticsEnabled)
        #expect(settings.lastConfiguration == SessionConfiguration(plannedSeconds: 60, preparationSeconds: 10))
    }

    @Test func appearanceIsPersisted() throws {
        let defaults = try makeDefaults()
        UserSettings(defaults: defaults).appearance = .dark
        #expect(UserSettings(defaults: defaults).appearance == .dark)
    }

    @Test func coachStyleIsPersisted() throws {
        let defaults = try makeDefaults()
        UserSettings(defaults: defaults).coachStyle = .cheeky
        #expect(UserSettings(defaults: defaults).coachStyle == .cheeky)
    }

    @Test func postureHintsArePersisted() throws {
        let defaults = try makeDefaults()
        UserSettings(defaults: defaults).postureHintsEnabled = false
        #expect(!UserSettings(defaults: defaults).postureHintsEnabled)
    }

    @Test func hapticsArePersisted() throws {
        let defaults = try makeDefaults()
        UserSettings(defaults: defaults).hapticsEnabled = false
        #expect(!UserSettings(defaults: defaults).hapticsEnabled)
    }

    @Test func rememberConfigurationStoresBothValues() throws {
        let defaults = try makeDefaults()
        let configuration = SessionConfiguration(plannedSeconds: 120, preparationSeconds: 20)
        let settings = UserSettings(defaults: defaults)
        settings.rememberConfiguration(configuration)
        #expect(settings.lastConfiguration == configuration)
        #expect(UserSettings(defaults: defaults).lastConfiguration == configuration)
    }

    @Test func invalidStoredValuesFallBack() throws {
        let defaults = try makeDefaults()
        defaults.set(7, forKey: "userSettings.lastPlannedSeconds")
        defaults.set(10, forKey: "userSettings.lastPreparationSeconds")
        defaults.set("unknown", forKey: "userSettings.coachStyle")
        defaults.set("unknown", forKey: "userSettings.appearance")
        let settings = UserSettings(defaults: defaults)
        #expect(settings.lastConfiguration.plannedSeconds == 10)
        #expect(settings.coachStyle == .demanding)
        #expect(settings.appearance == .system)
    }
}
