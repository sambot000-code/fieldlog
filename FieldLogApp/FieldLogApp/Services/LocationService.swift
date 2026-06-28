import Foundation
import CoreLocation
import Combine

/// Captures GPS coordinates + compass heading at the moment of event logging.
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var currentHeading: CLHeading?
    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1 // update every 1 degree change
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    /// Snapshot of current location + heading for attaching to an event
    func snapshot() -> (lat: Double, lon: Double, alt: Double, accuracy: Double, heading: Double?, headingAccuracy: Double?)? {
        guard let loc = currentLocation else { return nil }
        return (
            lat: loc.coordinate.latitude,
            lon: loc.coordinate.longitude,
            alt: loc.altitude,
            accuracy: loc.horizontalAccuracy,
            heading: currentHeading?.trueHeading,
            headingAccuracy: currentHeading?.headingAccuracy
        )
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
            start()
        }
    }
}
