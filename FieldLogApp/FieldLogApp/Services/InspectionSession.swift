import Foundation
import CoreLocation
import Combine

/// Manages the active inspection session — path recording, event linking.
/// One session at a time. Survives app backgrounding via saved state.
class InspectionSession: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = InspectionSession()

    @Published var activeInspection: Inspection? = nil
    @Published var isRecording = false

    // Recording config
    private let minDistanceMetres: Double = 15   // record point every 15m moved
    private let minIntervalSeconds: Double = 60  // or at least every 60s
    private var lastRecordedPoint: PathPoint? = nil
    private var lastRecordedTime: Date = .distantPast

    private let manager = CLLocationManager()
    private var currentLocation: CLLocation?

    private let saveURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("fieldlog_active_inspection.json")
    }()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        restoreIfNeeded()
    }

    // MARK: - Public API

    func start(title: String, projectId: UUID?) {
        guard activeInspection == nil else { return }
        let inspection = Inspection(
            projectId: projectId,
            title: title,
            startedAt: Date()
        )
        activeInspection = inspection
        isRecording = true
        manager.startUpdatingLocation()
        save()
        print("InspectionSession: started — \(title)")
    }

    func stop() -> Inspection? {
        guard var inspection = activeInspection else { return nil }
        inspection.endedAt = Date()
        inspection.status = .completed
        activeInspection = nil
        isRecording = false
        manager.stopUpdatingLocation()
        clearSave()
        print("InspectionSession: stopped — \(inspection.pathPoints.count) points, \(inspection.distanceLabel)")
        return inspection
    }

    func linkEvent(id: UUID) {
        guard activeInspection != nil else { return }
        if !(activeInspection!.eventIds.contains(id)) {
            activeInspection!.eventIds.append(id)
            save()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last,
              loc.horizontalAccuracy > 0,
              loc.horizontalAccuracy < 50,   // ignore poor fixes
              var inspection = activeInspection else { return }

        currentLocation = loc
        let now = Date()
        let point = PathPoint(
            latitude:  loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            altitude:  loc.altitude,
            timestamp: now,
            accuracy:  loc.horizontalAccuracy
        )

        // Record if moved enough OR enough time has passed
        let movedEnough = lastRecordedPoint.map { point.distanceTo($0) >= minDistanceMetres } ?? true
        let timeElapsed = now.timeIntervalSince(lastRecordedTime) >= minIntervalSeconds

        if movedEnough || timeElapsed {
            inspection.pathPoints.append(point)
            activeInspection = inspection
            lastRecordedPoint = point
            lastRecordedTime = now
            save()
        }
    }

    // MARK: - Persistence (survive app restarts mid-inspection)

    private func save() {
        guard let inspection = activeInspection else { return }
        try? JSONEncoder().encode(inspection).write(to: saveURL)
    }

    private func clearSave() {
        try? FileManager.default.removeItem(at: saveURL)
    }

    private func restoreIfNeeded() {
        guard FileManager.default.fileExists(atPath: saveURL.path),
              let data = try? Data(contentsOf: saveURL),
              let inspection = try? JSONDecoder().decode(Inspection.self, from: data) else { return }
        activeInspection = inspection
        isRecording = true
        manager.startUpdatingLocation()
        print("InspectionSession: restored active inspection — \(inspection.title)")
    }
}
