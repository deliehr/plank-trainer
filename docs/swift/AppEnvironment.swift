import Foundation
import Observation

/// Central entry point for app-wide dependencies, created once at app start and injected via `.environment(_:)`.
@Observable
final class AppEnvironment {
    let apiClient: WasteControllerAPIClient
    let userSettings: UserSettings

    init(
        apiClient: WasteControllerAPIClient = WasteControllerClient(baseURL: AppConfig.baseURL, apiKey: AppConfig.apiKey),
        userSettings: UserSettings = UserSettings()
    ) {
        self.apiClient = apiClient
        self.userSettings = userSettings
    }

    /// Loads appointments for the selected location. The persisted IDs can become stale when the
    /// backend changes, so on a 404 or an empty result the IDs are re-resolved via the stored
    /// names, saved, and the request is retried once.
    func loadAppointmentsForSelectedLocation() async throws -> [Appointment] {
        guard let place = userSettings.selectedPlace, let district = userSettings.selectedDistrict else { return [] }

        do {
            let appointments = try await apiClient.getAppointments(forPlace: place.id, district: district.id)
            if !appointments.isEmpty { return appointments }
        } catch WasteControllerError.httpError(statusCode: 404, _) {
            // Fall through to re-resolve by name.
        }

        guard let resolved = try await resolveLocation(place: place, district: district),
              resolved.place != place || resolved.district != district
        else {
            return try await apiClient.getAppointments(forPlace: place.id, district: district.id)
        }

        userSettings.selectedPlace = resolved.place
        userSettings.selectedDistrict = resolved.district
        return try await apiClient.getAppointments(forPlace: resolved.place.id, district: resolved.district.id)
    }

    private func resolveLocation(place: Place, district: District) async throws -> (place: Place, district: District)? {
        let places = try await apiClient.findPlaces(named: place.name)
        guard let freshPlace = Self.bestMatch(for: place.name, in: places) else { return nil }

        let districts = try await apiClient.findDistricts(forPlace: freshPlace.id, districtName: district.name)
        guard let freshDistrict = Self.bestMatch(for: district.name, in: districts) else { return nil }

        return (freshPlace, freshDistrict)
    }

    private static func bestMatch<T: Identifiable>(for name: String, in candidates: [T]) -> T? where T: NamedEntity {
        candidates.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
            ?? (candidates.count == 1 ? candidates.first : nil)
    }
}

private protocol NamedEntity {
    var name: String { get }
}

extension Place: NamedEntity {}
extension District: NamedEntity {}