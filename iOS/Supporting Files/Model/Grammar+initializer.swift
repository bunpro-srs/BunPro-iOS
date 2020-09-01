//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import Foundation

extension Grammar {
    @discardableResult
    convenience init(grammar: BPKGrammar, context: NSManagedObjectContext) {
        self.init(context: context)

        alternate = grammar.alternate
        caution = grammar.caution
        formal = grammar.formal
        identifier = grammar.identifier
        level = grammar.level
        lessonIdentifier = String(grammar.lessonIdentifier)
        isNew = grammar.isNew
        meaning = grammar.meaning
        structure = grammar.structure
        title = grammar.title
        yomikata = grammar.yomikata

        grammar.links.forEach { Link(link: $0, grammar: self, context: context) }
        grammar.sentences.forEach { Sentence(sentence: $0, grammar: self, context: context) }
    }
}

extension Grammar {
    static func fetchRequest(predicate: NSPredicate) -> NSFetchRequest<Grammar> {
        let request: NSFetchRequest<Grammar> = Grammar.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Grammar.identifier), ascending: true)
        ]
        return request
    }
}

extension Grammar {
    @objc var review: Review? {
        do {
            return try Review.review(for: self)
        } catch {
            log.error(error)
            return nil
        }
    }
}

extension Grammar: Comparable {
    public static func < (lhs: Grammar, rhs: Grammar) -> Bool {
        lhs.level ?? "" < rhs.level ?? "" && lhs.lessonIdentifier ?? "" < rhs.lessonIdentifier ?? ""
    }
}
