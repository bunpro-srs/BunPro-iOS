//
//  LessonsProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

public class LessonsProcedure: GroupProcedure, OutputProcedure {
    
    public var output: Pending<ProcedureResult<[JLPT]>> {
        get { return transformProcedure.output }
        set { assertionFailure("\(#function) should never be called.") }
    }
    
    public let completion: (([JLPT]?, Error?) -> Void)?
    
    private let lessonProcedure: _LessonsProcedure
    private let transformProcedure: TransformProcedure<_LessonData, [JLPT]>
    
    public init(presentingViewController: UIViewController, completion: (([JLPT]?, Error?) -> Void)? = nil) {
        
        self.completion = completion
        
        lessonProcedure = _LessonsProcedure(presentingViewController: presentingViewController)
        transformProcedure = TransformProcedure<_LessonData, [JLPT]> { $0.jlpt() }
        transformProcedure.injectResult(from: lessonProcedure)
        
        super.init(operations: [lessonProcedure, transformProcedure])
    }
}

fileprivate class _LessonsProcedure: BunPuroProcedure<_LessonData> {
    
    override var hasMilliseconds: Bool { return true }
    override var url: URL { return URL(string: "\(baseUrlString)lessons")! }
}

fileprivate struct _Lesson: Codable {
    
    struct Attributes: Codable {
        
        enum CodingKeys: String, CodingKey {
            case level = "jlpt-level"
        }
        
        let level: Int
    }
    
    struct Relationships: Codable {
        
        enum CodingKeys: String, CodingKey {
            case grammarPoints = "grammar-points"
        }
        
        struct GrammarPoints: Codable {
            
            struct Point: Codable {
                
                let id: String
            }
            
            let data: [Point]
        }
        
        let grammarPoints: GrammarPoints
    }
    
    let id: String
    let attributes: Attributes
    let relationships: Relationships
}

fileprivate enum Type: String, Codable {
    case grammar = "grammar-points"
    case supplementalLinks = "supplemental-links"
}

fileprivate class Point: Codable {
    let id: String
    let type: Type
}

fileprivate class _Grammar: Point {
    
    struct Attributes: Codable {
        
        let caution: String
        let meaning: String
        let structure: String
        let title: String
    }
    
    struct Relationships: Codable {
        
        enum CodingKeys: String, CodingKey {
            case exampleSentences = "example-sentences"
            case lesson
            case supplementalLinks = "supplemental-links"
        }
        
        struct ExampleSentences: Codable {
            
            struct Sentence: Codable {
                
                let id: String
            }
            
            let data: [Sentence]
        }
        
        struct Lesson: Codable {
            
            struct Data: Codable {
                
                let id: String
            }
            
            let data: Data
        }
        
        struct SupplementalLinks: Codable {
            
            struct Data: Codable {
                
                let id: String
            }
            
            let data: [Data]
        }
        
        let exampleSentences: ExampleSentences
        let lesson: Lesson
        let supplementalLinks: SupplementalLinks
    }
    
    let attributes: Attributes
    let relationships: Relationships
    
    enum CodingKeys : String, CodingKey {
        case attributes
        case relationships
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.attributes = try container.decode(Attributes.self, forKey: .attributes)
        self.relationships = try container.decode(Relationships.self, forKey: .relationships)
        
        try super.init(from: decoder)
    }
}

fileprivate class _SupplementalLink: Point {
    
    struct Attributes: Codable {
        
        let site: String
        let description: String
        let link: String
    }
    
    struct Relationships: Codable {
        
        enum CodingKeys: String, CodingKey {
            case grammar = "grammar-point"
        }
        
        struct Grammar: Codable {
            
            struct Data: Codable {
                
                let id: String
            }
            
            let data: Data
        }
        
        let grammar: Grammar
    }
    
    let attributes: Attributes
    let relationships: Relationships
    
    enum CodingKeys : String, CodingKey {
        case attributes
        case relationships
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.attributes = try container.decode(Attributes.self, forKey: .attributes)
        self.relationships = try container.decode(Relationships.self, forKey: .relationships)
        
        try super.init(from: decoder)
    }
}



fileprivate enum IncludedWrapper: Codable {
    
    func encode(to encoder: Encoder) throws {
        
    }
    
    case grammar(_Grammar)
    case link(_SupplementalLink)

    enum CodingKeys : String, CodingKey {
        case type
    }
    
    var point: Point {
        switch self {
        case .grammar(let s): return s
        case .link(let m): return m
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Type.self, forKey: .type)
        switch kind {
        case .grammar:
            self = .grammar(try _Grammar(from: decoder))
        case .supplementalLinks:
            self = .link(try _SupplementalLink(from: decoder))
        }
    }
}

fileprivate struct _LessonData: Codable {
    
    enum CodingKeys: String, CodingKey {
        case data
        case included
    }
    
    let data: [_Lesson]
    
    var grammar: [_Grammar]
    var supplemantalLinks: [_SupplementalLink]
    
    func jlpt() -> [JLPT] {
        return [3, 4, 5].map { level -> JLPT in
            
            let lessons = data.filter({ $0.attributes.level == level }).map { (l) -> Lesson in
                
                let grammar = self.allGrammar(for: l).map { (g) -> Grammar in
                    
                    let links = self.supplemantalLinks.filter({ $0.relationships.grammar.data.id == g.id }).map { link -> Grammar.Link in
                        return Grammar.Link(id: link.id, site: link.attributes.site, description: link.attributes.description, link: link.attributes.link)
                    }
                    
                    return Grammar(id: g.id,
                            title: g.attributes.title,
                            meaning: g.attributes.meaning,
                            caution: g.attributes.caution,
                            structure: g.attributes.structure,
                            supplementalLinks: links)
                }
                
                return Lesson(id: l.id, grammar: grammar)
            }
            
            return JLPT(level: level, lessons: lessons)
        }
    }
    
    private func allGrammar(for lesson: _Lesson) -> [_Grammar] {
        return grammar.filter({ $0.relationships.lesson.data.id == lesson.id })
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.data = try container.decode([_Lesson].self, forKey: .data)
        
        var grammarResults: [_Grammar] = []
        var linkResults: [_SupplementalLink] = []
        var resultsContainer = try container.nestedUnkeyedContainer(forKey: .included)
        while !resultsContainer.isAtEnd {
            let wrapper = try resultsContainer.decode(IncludedWrapper.self)
            
            switch wrapper {
            case .grammar(let g): grammarResults.append(g)
            case .link(let l): linkResults.append(l)
            }
        }
        self.grammar = grammarResults
        self.supplemantalLinks = linkResults
    }
    
    func encode(to encoder: Encoder) throws {
        
    }
}



