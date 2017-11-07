import Foundation

public struct UserResponse: Codable {
    
    public struct UserData: Codable {
        
        private enum CodingKeys: String, CodingKey {
            case id
            case attributes
        }
        
        public let id: String
        public let attributes: User
    }
    
    public let data: UserData
    
    public var user: User {
        return data.attributes
    }
}
