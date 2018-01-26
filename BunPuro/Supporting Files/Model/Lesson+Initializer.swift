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

extension Lesson {
    
    var progress: Float {
        
        do {
            let reviews = try Review.reviews(for: grammar!.allObjects as! [Grammar])
            
            let grammarCount = Float(grammar?.count ?? 0)
            let divisor = grammarCount > 0 ? grammarCount : 1
            
            return Float(reviews?.filter { $0.complete }.count ?? 0) / divisor
        } catch {
            print(error)
            return 0.0
        }
    }
}
