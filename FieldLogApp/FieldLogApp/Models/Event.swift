import Foundation
import CoreLocation

/// The core unit of FieldLog — one observable thing in the field.
public struct FieldEvent: Identifiable, Codable {
    public let id: UUID
    public var timestamp: Date
    public var latitude: Double?
    public var longitude: Double?

    public var title: String           // Short label (auto-generated or user-set)
    public var rawNote: String         // Raw typed or transcribed text
    public var aiSummary: String?      // AI-generated summary

    public var photoFilenames: [String] // Local filenames of attached photos
    public var audioFilename: String?   // Local filename of voice memo

    public var status: EventStatus
    public var tags: [String]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        latitude: Double? = nil,
        longitude: Double? = nil,
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
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        self.rawNote = rawNote
        self.aiSummary = aiSummary
        self.photoFilenames = photoFilenames
        self.audioFilename = audioFilename
        self.status = status
        self.tags = tags
    }
}

public enum EventStatus: String, Codable, CaseIterable {
    case draft      = "Draft"
    case submitted  = "Submitted"
    case reviewed   = "Reviewed"
}
