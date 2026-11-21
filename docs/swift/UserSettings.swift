import Observation
import SwiftUI

/// Persisted user choices: selected location, onboarding/skip state, and appearance/reminder
/// preferences. Backed by `UserDefaults`; `Place`/`District` are stored JSON-encoded since
/// `@AppStorage` has no native `Codable` support.
@Observable
final class UserSettings {
    enum Appearance: String, CaseIterable {
        case system, light, dark

        var label: String {
            switch self {
            case .system: return "System"
            case .light: return "Hell"
            case .dark: return "Dunkel"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    private let defaults: UserDefaults

    var selectedPlace: Place? {
        didSet { persist(selectedPlace, forKey: Keys.selectedPlace) }
    }

    var selectedDistrict: District? {
        didSet { persist(selectedDistrict, forKey: Keys.selectedDistrict) }
    }

    var hasSkippedOnboarding: Bool {
        didSet { defaults.set(hasSkippedOnboarding, forKey: Keys.hasSkippedOnboarding) }
    }

    var remindersEnabled: Bool {
        didSet { defaults.set(remindersEnabled, forKey: Keys.remindersEnabled) }
    }

    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedPlace = Self.load(Place.self, key: Keys.selectedPlace, from: defaults)
        self.selectedDistrict = Self.load(District.self, key: Keys.selectedDistrict, from: defaults)
        self.hasSkippedOnboarding = defaults.bool(forKey: Keys.hasSkippedOnboarding)
        self.remindersEnabled = defaults.bool(forKey: Keys.remindersEnabled)
        self.appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
    }

    private func persist<T: Encodable>(_ value: T?, forKey key: String) {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private enum Keys {
        static let selectedPlace = "userSettings.selectedPlace"
        static let selectedDistrict = "userSettings.selectedDistrict"
        static let hasSkippedOnboarding = "userSettings.hasSkippedOnboarding"
        static let remindersEnabled = "userSettings.remindersEnabled"
        static let appearance = "userSettings.appearance"
    }
}