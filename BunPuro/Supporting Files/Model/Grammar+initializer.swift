//
//  Grammar+initializer.swift
//  BunPuro
//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Foundation
import CoreData
import BunPuroKit

extension Grammar {
    
    @discardableResult
    convenience init(grammar: BPKGrammar, lesson: Lesson, context: NSManagedObjectContext) {
        
        self.init(context: context)
        
        alternate = grammar.alternate
        caution = grammar.caution
        formal = grammar.formal
        identifier = grammar.identifier
        isNew = grammar.isNew
        meaning = grammar.meaning
        structure = grammar.structure
        title = grammar.title
        yomikata = grammar.yomikata
        
        self.lesson = lesson
        
        grammar.supplementalLinks.forEach {  Link(link: $0, grammar: self, context: context) }
        grammar.exampleSentences.forEach { Sentence(sentence: $0, grammar: self, context: context) }
    }
}

extension Grammar {
    
    var review: Review? {
        
        do {
            return try Review.review(for: self)
        } catch {
            print(error)
            return nil
        }
    }
}
