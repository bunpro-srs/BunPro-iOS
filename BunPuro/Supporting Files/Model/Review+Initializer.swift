//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import Foundation

extension Review {
    @discardableResult
    convenience init(review: BPKReview, context: NSManagedObjectContext) {
        self.init(context: context)

        identifier = review.identifier
        complete = review.complete ?? true
        createdDate = review.createdDate
        grammarIdentifier = review.grammarIdentifier
        lastStudiedDate = review.lastStudiedDate
        nextReviewDate = review.nextReviewDate
        readingIdentifiers = review.readingsIdentifiers as NSArray?
        selfStudy = review.selfStudy
        streak = review.streak
        studyQuestionIdentifier = review.studyQuenstionIdentifier ?? 0
        timesCorrect = review.timesCorrect
        timesIncorrect = review.timesIncorrect
        updatedDate = review.updatedDate
        userIdentifier = review.userIdentifier
        wasCorrect = review.wasCorrect ?? false
        reviewType = review.reviewType?.rawValue
    }
}

extension Review {
    static func review(for grammar: Grammar) throws -> Review? {
        let request: NSFetchRequest<Review> = Review.fetchRequest()
        request.fetchLimit = 1
        request.fetchBatchSize = 1

        request.predicate = NSPredicate(format: "%K = %d", #keyPath(Review.grammarIdentifier), grammar.identifier)

        return try grammar.managedObjectContext?.fetch(request).first
    }

    static func reviews(for grammar: [Grammar]) throws -> [Review]? {
        let request: NSFetchRequest<Review> = Review.fetchRequest()

        let grammarIdentifierPredicate = NSPredicate(format: "%K IN %@", #keyPath(Review.grammarIdentifier), grammar.map { $0.identifier })
        let reviewTypePredicate = NSPredicate(format: "%K == %@", #keyPath(Review.reviewType), BPKReview.ReviewType.standard.rawValue)

        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [grammarIdentifierPredicate, reviewTypePredicate])

        request.predicate = compoundPredicate
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Review.identifier), ascending: true)]

        return try grammar.first?.managedObjectContext?.fetch(request)
    }
}
