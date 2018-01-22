//
//  Lesson+Initializer.swift
//  BunPuro
//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Foundation
import CoreData
import BunPuroKit

extension Lesson {
    
    @discardableResult
    convenience init(lesson: BPKLesson, jlpt: JLPT, context: NSManagedObjectContext) {
        
        self.init(context: context)
        
        identifier = lesson.identifier
        order = lesson.identifier
        createdDate = lesson.createdDate
        updatedDate = lesson.updatedDate
        self.jlpt = jlpt
        
        lesson.grammar.forEach { Grammar(grammar: $0, lesson: self, context: context) }
    }
}
