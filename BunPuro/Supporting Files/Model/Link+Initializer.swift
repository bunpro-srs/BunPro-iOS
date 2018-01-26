//
//  Link+Initializer.swift
//  BunPuro
//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Foundation
import CoreData
import BunPuroKit

extension Link {
    
    @discardableResult
    convenience init(link: BPKLink, grammar: Grammar, context: NSManagedObjectContext) {
        
        self.init(context: context)
        
        id = link.identifier
        about = link.description
        site = link.site
        url = URL(string: link.link.trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        createdDate = link.createdDate
        updatedDate = link.updatedDate
        self.grammar = grammar
    }
}
