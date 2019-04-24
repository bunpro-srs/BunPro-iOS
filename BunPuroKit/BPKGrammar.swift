//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

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

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try values.decode(Int64.self, forKey: .identifier)
        title = (try? values.decode(String.self, forKey: .title)) ?? "This is a faulty grammar point, sorry for that... ._."
        createdDate = try values.decode(Date.self, forKey: .createdDate)
        updatedDate = try values.decode(Date.self, forKey: .updatedDate)
        alternate = try? values.decode(String.self, forKey: .alternate)
        meaning = (try? values.decode(String.self, forKey: .meaning)) ?? ""
        caution = (try? values.decode(String.self, forKey: .caution)) ?? ""
        structure = (try? values.decode(String.self, forKey: .structure)) ?? ""
        formal = try values.decode(Bool.self, forKey: .formal)
        level = (try? values.decode(String.self, forKey: .level)) ?? "0"
        lessonIdentifier = (try? values.decode(Int.self, forKey: .lessonIdentifier)) ?? 0
        isNew = try values.decode(Bool.self, forKey: .isNew)
        yomikata = (try? values.decode(String.self, forKey: .yomikata)) ?? ""
        exampleSentences = try values.decode([BPKSentence].self, forKey: .exampleSentences)
        supplementalLinks = try values.decode([BPKLink].self, forKey: .supplementalLinks)
    }
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
