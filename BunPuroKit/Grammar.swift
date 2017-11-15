import Foundation

// JLPT Level -> Lesson -> Grammar

/* JLPT
 * -> name: String
 * -> lessons: [Lesson]
 */

/* Lesson
 * -> order: Int
 * -> grammar: [Grammar]
 */

/* Grammar
 * -> title: String
 * -> meaning: String
 * -> exampleSentences: [Sentence]
 * -> supplementalLinks: [Link]
 */

public struct Grammar {
    
    struct Sentence {
        
        let id: String
    }
    
    struct Link {
        
        let id: String
    }
    
    public let id: String
    public let title: String
    public let meaning: String
//    let exampleSentence: [Sentence]
//    let supplementalLinks: [Link]
    
    public init(id: String, title: String, meaning: String) {
        self.id = id
        self.title = title
        self.meaning = meaning
    }
}

public struct Lesson {
    
    public let id: String
    public var order: Int {
        return Int(id)!
    }
    public let grammar: [Grammar]
    
    public init(id: String, grammar: [Grammar]) {
        self.id = id
        self.grammar = grammar
    }
}

public struct JLPT {
    
    public let level: Int
    public var name: String {
        return "N\(level)"
    }
    public let lessons: [Lesson]
    
    public init(level: Int, lessons: [Lesson]) {
        self.level = level
        self.lessons = lessons
    }
}
