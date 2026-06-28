import Foundation

/// An active inspection session — tracks path + links to all events logged during it.
public struct Inspection: Identifiable, Codable {
    public let id: UUID
    public var projectId: UUID?
    public var title: String
    public var startedAt: Date
    public var endedAt: Date?
    public var status: InspectionStatus

    public var pathPoints: [PathPoint]   // Breadcrumb trail
    public var eventIds: [UUID]          // Events logged during this inspection

    public init(
        id: UUID = UUID(),
        projectId: UUID? = nil,
        title: String = "",
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        status: InspectionStatus = .active,
        pathPoints: [PathPoint] = [],
        eventIds: [UUID] = []
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.status = status
        self.pathPoints = pathPoints
        self.eventIds = eventIds
    }

    public var duration: TimeInterval {
        (endedAt ?? Date()).timeIntervalSince(startedAt)
    }

    public var durationLabel: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        if mins >= 60 {
            return "\(mins / 60)h \(mins % 60)m"
        }
        return "\(mins)m \(secs)s"
    }

    public var distanceMetres: Double {
        guard pathPoints.count > 1 else { return 0 }
        var total = 0.0
        for i in 1..<pathPoints.count {
            total += pathPoints[i].distanceTo(pathPoints[i - 1])
        }
        return total
    }

    public var distanceLabel: String {
        let m = distanceMetres
        if m >= 1000 { return String(format: "%.1f km", m / 1000) }
        return String(format: "%.0f m", m)
    }
}

public enum InspectionStatus: String, Codable {
    case active     = "Active"
    case completed  = "Completed"
}

// MARK: - Path Point

public struct PathPoint: Codable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double
    public let timestamp: Date
    public let accuracy: Double

    public init(latitude: Double, longitude: Double, altitude: Double,
                timestamp: Date = Date(), accuracy: Double) {
        self.latitude  = latitude
        self.longitude = longitude
        self.altitude  = altitude
        self.timestamp = timestamp
        self.accuracy  = accuracy
    }

    /// Haversine distance to another point in metres
    public func distanceTo(_ other: PathPoint) -> Double {
        let R = 6_371_000.0
        let φ1 = latitude  * .pi / 180
        let φ2 = other.latitude  * .pi / 180
        let Δφ = (other.latitude  - latitude)  * .pi / 180
        let Δλ = (other.longitude - longitude) * .pi / 180
        let a = sin(Δφ/2) * sin(Δφ/2)
              + cos(φ1) * cos(φ2) * sin(Δλ/2) * sin(Δλ/2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
