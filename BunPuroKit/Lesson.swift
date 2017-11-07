//
//  Lesson.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation

public struct LessonResponse: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case lessons = "data"
    }
    
    public let lessons: [Lesson]
}

public struct Lesson: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case id
        case level = "attributes"
        case grammarPointIds = "relationships"
    }
    
    private enum AttributeKeys: String, CodingKey {
        case level = "jlpt-level"
    }
    
    private enum RelationshipKeys: String, CodingKey {
        case grammarPoints = "grammar-points"
    }
    
    private enum RelationshipDataKeys: String, CodingKey {
        case data
    }
    
    private enum GrammarPointKeys: String, CodingKey {
        case id
    }
    
    private struct GrammarPoint: Codable {
        
        private enum CodingKeys: String, CodingKey {
            case id
        }
        
        let id: String
    }
    
    public let id: String
    public let level: Int
    
    public let grammarPointIds: [String]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.level = try container.nestedContainer(keyedBy: AttributeKeys.self, forKey: .level).decode(Int.self, forKey: .level)
        
        let relationshipsContainer = try container.nestedContainer(keyedBy: RelationshipKeys.self, forKey: .grammarPointIds)
        let relationshipsDataContainer = try relationshipsContainer.nestedContainer(keyedBy: RelationshipDataKeys.self, forKey: .grammarPoints)
        let points = try relationshipsDataContainer.decode([GrammarPoint].self, forKey: .data)
        
        self.grammarPointIds = points.flatMap { $0.id }
    }
}
