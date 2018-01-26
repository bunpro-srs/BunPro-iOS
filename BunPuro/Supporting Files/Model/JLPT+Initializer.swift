//
//  JLPT+Initializer.swift
//  BunPuro
//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Foundation
import CoreData
import BunPuroKit

extension JLPT {
    
    @discardableResult
    convenience init(jlpt: BPKJlpt, context: NSManagedObjectContext) {
        
        self.init(context: context)
        
        level = Int64(jlpt.level)
        name = jlpt.name
        
        jlpt.lessons.forEach { Lesson(lesson: $0, jlpt: self, context: context) }
    }
}
