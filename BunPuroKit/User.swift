import Foundation

public struct User: Codable {
    
    public enum CodingKeys: String, CodingKey {
        case name = "username"
        case isActivated = "activated"
        case createdAt = "created-at"
        case updatedAt = "updated-at"
    }
    
    public let name: String
    public let isActivated: Bool
    public let createdAt: Date
    public let updatedAt: Date
}
