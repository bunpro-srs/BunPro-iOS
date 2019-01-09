import Foundation

public struct BPKSentence: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case grammarIdentifier = "grammar_point_id"
        case japanese
        case english
        case structure
        case alternativeJapanese = "alternate_japanese"
        case createdDate = "created_at"
        case updatedDate = "updated_at"
        case audio = "audio_link"
    }
    
    public let identifier: Int64
    public let grammarIdentifier: Int64
    public let japanese: String
    public let english: String
    public let structure: String
    public let alternativeJapanese: String?
    public let createdDate: Date
    public let updatedDate: Date
    public let audio: String?
}

public struct BPKLink: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case grammarIdentifier = "grammar_point_id"
        case site
        case link
        case description
        case createdDate = "created_at"
        case updatedDate = "updated_at"
    }
    
    public let identifier: Int64
    public let grammarIdentifier: Int64
    public let site: String
    public let description: String
    public let link: String
    public let createdDate: Date
    public let updatedDate: Date
}

public struct BPKGrammar: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case title
        case alternate
        case meaning
        case caution
        case structure
        case formal
        case level
        case lessonIdentifier = "lesson_id"
        case isNew = "new_grammar"
        case yomikata
        case exampleSentences = "example_sentences"
        case supplementalLinks = "supplemental_links"
        case createdDate = "created_at"
        case updatedDate = "updated_at"
    }
    
    public let identifier: Int64
    public let title: String
    public let createdDate: Date
    public let updatedDate: Date
    public let alternate: String?
    public let meaning: String
    public let caution: String
    public let structure: String
    public let formal: Bool
    public let level: String
    public let lessonIdentifier: Int
    public let isNew: Bool
    public let yomikata: String
    public let exampleSentences: [BPKSentence]
    public let supplementalLinks: [BPKLink]
}

public struct BPKLesson: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case jlptLevel = "jlpt_level"
        case grammar = "grammar_points"
        case createdDate = "created_at"
        case updatedDate = "updated_at"
    }
    
    public let identifier: Int64
    public let jlptLevel: Int
    public let createdDate: Date
    public let updatedDate: Date
    public let grammar: [BPKGrammar]
}

public struct BPKJlpt {
    
    public let level: Int
    public var name: String {
        return "N\(level)"
    }
    public let lessons: [BPKLesson]
    
    public init(level: Int, lessons: [BPKLesson]) {
        self.level = level
        self.lessons = lessons
    }
}
