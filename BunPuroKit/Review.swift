import Foundation

public struct BPKReview: Codable {
    
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case userIdentifier = "user_id"
        case studyQuenstionIdentifier = "study_question_id"
        case grammarIdentifier = "grammar_point_id"
        case timesCorrect = "times_correct"
        case timesIncorrect = "times_incorrect"
        case streak
        case nextReviewDate = "next_review"
        case lastStudiedDate = "last_studied_at"
        case createdDate = "created_at"
        case updatedDate = "updated_at"
        case readingsIdentifiers = "readings"
        case complete
        case wasCorrect = "was_correct"
        case selfStudy = "self_study"
    }
    
    public let identifier: Int64
    public let userIdentifier: Int64
    public let studyQuenstionIdentifier: Int64
    public let grammarIdentifier: Int64
    public let timesCorrect: Int64
    public let timesIncorrect: Int64
    public let streak: Int64
    public let nextReviewDate: Date
    public let lastStudiedDate: Date?
    public let createdDate: Date
    public let updatedDate: Date
    public let readingsIdentifiers: [Int64]
    public let complete: Bool
    public let wasCorrect: Bool?
    public let selfStudy: Bool
}
