//
//  Review+Initializer.swift
//  BunPuro
//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Foundation
import CoreData
import BunPuroKit

extension Review {
    
    @discardableResult
    convenience init(review: BPKReview, context: NSManagedObjectContext) {
        
        self.init(context: context)
        
        identifier = review.identifier
        complete = review.complete
        createdDate = review.createdDate
        grammarIdentifier = review.grammarIdentifier
        lastStudiedDate = review.lastStudiedDate
        nextReviewDate = review.nextReviewDate
        readingIdentifiers = review.readingsIdentifiers as NSArray
        selfStudy = review.selfStudy
        streak = review.streak
        studyQuestionIdentifier = review.studyQuenstionIdentifier
        timesCorrect = review.timesCorrect
        timesIncorrect = review.timesIncorrect
        updatedDate = review.updatedDate
        userIdentifier = review.userIdentifier
        wasCorrect = review.wasCorrect
    }
}
