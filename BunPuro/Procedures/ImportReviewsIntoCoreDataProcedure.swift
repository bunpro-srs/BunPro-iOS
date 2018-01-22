//
//  ImportReviewsIntoCoreDataProcedure.swift
//  BunPuro
//
//  Created by Andreas Braun on 19.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Foundation
import BunPuroKit
import ProcedureKit
import CoreData

final class ImportReviewsIntoCoreDataProcedure: Procedure {
    
    let stack: CoreDataStack
    let reviews: [BunPuroKit.BPKReview]
    
    init(stack: CoreDataStack = AppDelegate.coreDataStack, reviews: [BunPuroKit.BPKReview]) {
        
        self.stack = stack
        self.reviews = reviews
        
        super.init()
    }
    
    override func execute() {
        guard !isCancelled else { return }
        
        stack.storeContainer.performBackgroundTask { (context) in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            self.reviews.forEach { (review) in
                
                let newReview = Review(context: context)
                
                newReview.identifier = review.identifier
                newReview.complete = review.complete
                newReview.createdDate = review.createdDate
                newReview.grammarIdentifier = review.grammarIdentifier
                newReview.lastStudiedDate = review.lastStudiedDate
                newReview.nextReviewDate = review.nextReviewDate
                newReview.readingIdentifiers = review.readingsIdentifiers as NSArray
                newReview.selfStudy = review.selfStudy
                newReview.streak = review.streak
                newReview.studyQuestionIdentifier = review.studyQuenstionIdentifier
                newReview.timesCorrect = review.timesCorrect
                newReview.timesIncorrect = review.timesIncorrect
                newReview.updatedDate = review.updatedDate
                newReview.userIdentifier = review.userIdentifier
                newReview.wasCorrect = review.wasCorrect
            }
            
            do {
                try context.save()
                self.finish()
            } catch {
                self.finish(withError: error)
            }
        }
    }
}
