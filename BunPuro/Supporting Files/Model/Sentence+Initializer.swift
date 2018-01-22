//
//  Sentence+Initializer.swift
//  BunPuro
//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Foundation
import CoreData
import BunPuroKit

extension Sentence {
    
    @discardableResult
    convenience init(sentence: BPKSentence, grammar: Grammar, context: NSManagedObjectContext) {
        
        self.init(context: context)
        
        identifier = sentence.identifier
        japanese = sentence.japanese
        english = sentence.english
        structure = sentence.structure
        createdDate = sentence.createdDate
        updatedDate = sentence.updatedDate
        alternativeJapanese = sentence.alternativeJapanese
        self.grammar = grammar
    }
}
