//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import BunPuroKit
import CoreData
import Foundation

extension Link {
    @discardableResult
    convenience init(link: BPKLink, grammar: Grammar, context: NSManagedObjectContext) {
        self.init(context: context)

        id = link.identifier
        about = link.description
        site = link.site

        let linksString = link.link.trimmingCharacters(in: .whitespacesAndNewlines)

        if let newUrl = URL(string: linksString) {
            url = newUrl
        } else {
            url = URL(string: linksString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
        }

        createdDate = link.createdDate
        updatedDate = link.updatedDate
        self.grammar = grammar
    }
}
