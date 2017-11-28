import Foundation

public struct Grammar {
    
    public struct Sentence {
        
        public let id: String
        public let japanese: String
        public let english: String
        public let structure: String
    }
    
    public struct Link {
        
        public let id: String
        public let site: String
        public let description: String
        public let link: String
    }
    
    public let id: String
    public let title: String
    public let meaning: String
    public let caution: String
    public let structure: String
    public let exampleSentences: [Sentence]
    public let supplementalLinks: [Link]
    
    init(id: String, title: String, meaning: String, caution: String, structure: String, exampleSentences: [Sentence], supplementalLinks: [Link]) {
        self.id = id
        self.title = title
        self.meaning = meaning
        self.caution = caution
        self.structure = structure
        self.exampleSentences = exampleSentences
        self.supplementalLinks = supplementalLinks
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
