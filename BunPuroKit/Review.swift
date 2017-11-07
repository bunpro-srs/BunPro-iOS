import Foundation

public struct Review: Codable {
    
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case attributes
    }
    
    public struct ReviewAttributes: Codable {
        
        enum CodingKeys: String, CodingKey {
            case complete
            case lastStudiedAt = "last-studied-at"
            case nextReviewDate = "next-review"
            case streak
            case timesCorrect = "times-correct"
            case timesIncorrect = "times-incorrect"
            case wasCorrect = "was-correct"
        }
        
        public let complete: Bool
        public let lastStudiedAt: Date?
        public let nextReviewDate: Date
        public let streak: Int
        public let timesCorrect: Int
        public let timesIncorrect: Int
        public let wasCorrect: Bool?
    }
    
    public let identifier: String
    public let attributes: ReviewAttributes

}
