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
        caution = grammar.caution.htmlAttributedString?.string
        formal = grammar.formal
        identifier = grammar.identifier
        isNew = grammar.isNew
        meaning = grammar.meaning.htmlAttributedString?.string
        structure = grammar.structure.htmlAttributedString?.string
        title = grammar.title.htmlAttributedString?.string
        yomikata = grammar.yomikata
        
        self.lesson = lesson
        
        grammar.supplementalLinks.forEach {  Link(link: $0, grammar: self, context: context) }
        grammar.exampleSentences.forEach { Sentence(sentence: $0, grammar: self, context: context) }
    }
}
