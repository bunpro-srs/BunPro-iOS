import Foundation

public struct UserResponse: Codable {
    
    public struct UserData: Codable {
        public let id: String
        public let type: ResourceType
        public let attributes: User
    }
    
    public let data: UserData
    
    public var user: User {
        return data.attributes
    }
}
