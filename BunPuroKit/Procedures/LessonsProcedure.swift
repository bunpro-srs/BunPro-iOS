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

let lessonsUrlString = "\(baseUrlString)lessons/"

class LessonsProcedure: GroupProcedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<[JLPT]>> = .pending
    
    let completion: (([JLPT]?, Error?) -> Void)?
    
    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>
    private let _transformProcedure: TransformProcedure<Data, [JLPT]>
    
    init(completion: (([JLPT]?, Error?) -> Void)? = nil) {
        
        let url = URL(string: lessonsUrlString + Server.apiToken)!
        let request = URLRequest(url: url)
        
        _networkProcedure = NetworkProcedure(resilience: DefaultNetworkResilience(requestTimeout: nil)) { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, [JLPT]> { try CustomDecoder.decode(_LessonData.self, from: $0, hasMilliseconds: true).jlpt() }
        _transformProcedure.injectPayload(fromNetwork: _networkProcedure)
        
        self.completion = completion
        
        super.init(operations: [_networkProcedure, _transformProcedure])
        
        self.add(observer: NetworkObserver(controller: NetworkActivityController(timerInterval: 1.0, indicator: UIApplication.shared)))
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        
        print(errors)
        output = _transformProcedure.output
        
        completion?(output.value?.value, output.error)
    }
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

fileprivate struct _Grammar: Codable {
    
    struct Attributes: Codable {
        
        let meaning: String
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
    
    let id: String
    let attributes: Attributes
    let relationships: Relationships
}

fileprivate struct _LessonData: Codable {
    
    let data: [_Lesson]
    let included: [_Grammar]
    
    func jlpt() -> [JLPT] {
        return [3, 4, 5].map { level -> JLPT in
            
            let lessons = data.filter({ $0.attributes.level == level }).map { (l) -> Lesson in
                
                let grammar = self.included.filter({ $0.relationships.lesson.data.id == l.id }).map { Grammar(id: $0.id, title: $0.attributes.title, meaning: $0.attributes.meaning) }
                
                return Lesson(id: l.id, grammar: grammar)
            }
            
            return JLPT(level: level, lessons: lessons)
        }
    }
}
