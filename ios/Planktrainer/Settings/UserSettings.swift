import Observation
import SwiftUI

@Observable
final class UserSettings {
    enum Appearance: String, CaseIterable, Sendable {
        case system, light, dark

        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    @ObservationIgnored private let defaults: UserDefaults

    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    var coachStyle: CoachStyle {
        didSet { defaults.set(coachStyle.rawValue, forKey: Keys.coachStyle) }
    }

    var postureHintsEnabled: Bool {
        didSet { defaults.set(postureHintsEnabled, forKey: Keys.postureHintsEnabled) }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    private(set) var lastConfiguration: SessionConfiguration

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = defaults.string(forKey: Keys.appearance).flatMap(Appearance.init(rawValue:)) ?? .system
        coachStyle = defaults.string(forKey: Keys.coachStyle).flatMap(CoachStyle.init(rawValue:)) ?? .standard
        postureHintsEnabled = defaults.object(forKey: Keys.postureHintsEnabled) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        lastConfiguration = Self.loadConfiguration(from: defaults)
    }

    /// Stores planned and preparation seconds as the new defaults (spec 3.2, 3.9).
    func rememberConfiguration(_ configuration: SessionConfiguration) {
        lastConfiguration = configuration
        defaults.set(configuration.plannedSeconds, forKey: Keys.lastPlannedSeconds)
        defaults.set(configuration.preparationSeconds, forKey: Keys.lastPreparationSeconds)
    }

    private static func loadConfiguration(from defaults: UserDefaults) -> SessionConfiguration {
        let standard = SessionConfiguration.standard
        guard
            let planned = defaults.object(forKey: Keys.lastPlannedSeconds) as? Int,
            let preparation = defaults.object(forKey: Keys.lastPreparationSeconds) as? Int
        else { return standard }
        return SessionConfiguration(plannedSeconds: planned, preparationSeconds: preparation)
    }

    private enum Keys {
        static let appearance = "userSettings.appearance"
        static let coachStyle = "userSettings.coachStyle"
        static let postureHintsEnabled = "userSettings.postureHintsEnabled"
        static let hapticsEnabled = "userSettings.hapticsEnabled"
        static let lastPlannedSeconds = "userSettings.lastPlannedSeconds"
        static let lastPreparationSeconds = "userSettings.lastPreparationSeconds"
    }
}
