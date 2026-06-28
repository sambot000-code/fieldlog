import Foundation

/// A site or project that events get logged against.
public struct Project: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var siteCode: String?      // Short code e.g. "AGK-01"
    public var description: String?
    public var color: String          // Hex string for UI accent
    public var isActive: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        siteCode: String? = nil,
        description: String? = nil,
        color: String = "#15B0C1",
        isActive: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.siteCode = siteCode
        self.description = description
        self.color = color
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
