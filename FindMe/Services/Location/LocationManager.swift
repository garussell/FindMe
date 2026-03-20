import CoreLocation
import Foundation
import Observation

/// Manages device geolocation and reverse geocoding for the location search field.
///
/// Permission flow:
/// 1. On first use, checks UserDefaults for a stored preference ("location-permission-asked").
/// 2. If the user hasn't been asked yet and taps "Use my location", requests when-in-use authorization.
/// 3. If authorized, fetches a single location fix and reverse-geocodes it to "City, State" via CLGeocoder.
/// 4. If denied or restricted, sets `state` to `.denied` — the UI shows the field normally with no disruption.
/// 5. Stores the fact that permission was requested so repeat visitors aren't re-prompted on every launch.
///
/// Error handling:
/// - Timeout: If no location fix within 10 seconds, falls back to `.failed` state.
/// - Geocoding failure: Shows the raw coordinates description and lets the user clear/change.
/// - Location unavailable: Falls back gracefully with no disruption to the text field.
@MainActor
@Observable
final class LocationManager: NSObject {
    enum State: Equatable {
        case idle
        case requesting
        case locating
        case resolved(String)
        case denied
        case failed(String)
    }

    var state: State = .idle

    /// The resolved city/state string, if available.
    var resolvedLocation: String? {
        if case .resolved(let location) = state { return location }
        return nil
    }

    var isLoading: Bool {
        state == .requesting || state == .locating
    }

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let defaults: UserDefaults
    private let permissionAskedKey = "location-permission-asked"
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Checks current authorization without prompting. Call on appear to restore previous state.
    func checkExistingAuthorization() {
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // User previously granted — we can offer the button but don't auto-locate
            break
        case .denied, .restricted:
            state = .denied
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    /// Requests location and reverse geocodes to "City, State".
    /// Shows the system permission prompt if needed.
    func requestLocation() async {
        let status = locationManager.authorizationStatus

        // If not yet determined, request authorization first
        if status == .notDetermined {
            state = .requesting
            locationManager.requestWhenInUseAuthorization()
            defaults.set(true, forKey: permissionAskedKey)

            // Wait briefly for the authorization callback
            try? await Task.sleep(for: .milliseconds(500))

            // Re-check after prompt
            let newStatus = locationManager.authorizationStatus
            guard newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways else {
                if newStatus == .denied || newStatus == .restricted {
                    state = .denied
                } else {
                    // Still not determined — user hasn't responded yet
                    // We'll wait for the delegate callback
                    state = .requesting
                    return
                }
                return
            }
        }

        guard status == .authorizedWhenInUse || status == .authorizedAlways ||
              locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            state = .denied
            return
        }

        state = .locating

        // Get a single location fix with a timeout
        let location: CLLocation? = await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            self.locationManager.requestLocation()

            // Timeout after 10 seconds
            Task {
                try? await Task.sleep(for: .seconds(10))
                if let pending = self.locationContinuation {
                    self.locationContinuation = nil
                    pending.resume(returning: nil)
                }
            }
        }

        guard let location else {
            state = .failed("Could not determine your location. Please enter it manually.")
            return
        }

        // Reverse geocode to a readable city/state string
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let city = placemark.locality ?? placemark.subAdministrativeArea ?? ""
                let stateAbbr = placemark.administrativeArea ?? ""
                let locationString = [city, stateAbbr].filter { !$0.isEmpty }.joined(separator: ", ")
                if locationString.isEmpty {
                    state = .failed("Could not determine your city. Please enter it manually.")
                } else {
                    state = .resolved(locationString)
                }
            } else {
                state = .failed("Could not determine your city. Please enter it manually.")
            }
        } catch {
            state = .failed("Location lookup failed. Please enter it manually.")
        }
    }

    /// Clears the resolved location, returning to idle state.
    func clearLocation() {
        state = .idle
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: @preconcurrency CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        Task { @MainActor in
            if let continuation = self.locationContinuation {
                self.locationContinuation = nil
                continuation.resume(returning: location)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let continuation = self.locationContinuation {
                self.locationContinuation = nil
                continuation.resume(returning: nil)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                // If we were waiting on authorization, now go fetch location
                if self.state == .requesting {
                    await self.requestLocation()
                }
            case .denied, .restricted:
                self.state = .denied
            default:
                break
            }
        }
    }
}
