import Foundation

/// The core unit of FieldLog — one observable thing in the field.
public struct FieldEvent: Identifiable, Codable {
    public let id: UUID
    public var timestamp: Date

    // Project linkage
    public var projectId: UUID?

    // Location
    public var latitude: Double?
    public var longitude: Double?
    public var altitude: Double?
    public var horizontalAccuracy: Double?
    public var headingDegrees: Double?
    public var headingAccuracy: Double?

    public var title: String
    public var rawNote: String
    public var aiSummary: String?

    public var photoFilenames: [String]
    public var audioFilename: String?

    public var status: EventStatus
    public var tags: [String]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        projectId: UUID? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        altitude: Double? = nil,
        horizontalAccuracy: Double? = nil,
        headingDegrees: Double? = nil,
        headingAccuracy: Double? = nil,
        title: String = "",
        rawNote: String = "",
        aiSummary: String? = nil,
        photoFilenames: [String] = [],
        audioFilename: String? = nil,
        status: EventStatus = .draft,
        tags: [String] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.projectId = projectId
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.headingDegrees = headingDegrees
        self.headingAccuracy = headingAccuracy
        self.title = title
        self.rawNote = rawNote
        self.aiSummary = aiSummary
        self.photoFilenames = photoFilenames
        self.audioFilename = audioFilename
        self.status = status
        self.tags = tags
    }

    /// Human-readable compass direction from heading degrees
    public var headingLabel: String? {
        guard let h = headingDegrees else { return nil }
        let dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE",
                    "S","SSW","SW","WSW","W","WNW","NW","NNW"]
        let index = Int((h + 11.25) / 22.5) % 16
        return dirs[index]
    }
}

public enum EventStatus: String, Codable, CaseIterable {
    case draft      = "Draft"
    case submitted  = "Submitted"
    case reviewed   = "Reviewed"
}
