//
//  ResetReviewsProcedure.swift
//  BunPuro
//
//  Created by Andreas Braun on 19.08.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import CoreData

final class ResetReviewsProcedure: Procedure {
    
    let stack: CoreDataStack
    
    init(stack: CoreDataStack = AppDelegate.coreDataStack) {
        
        self.stack = stack
        
        super.init()
    }
    
    override func execute() {
        guard !isCancelled else { return }
        
        stack.storeContainer.performBackgroundTask { (context) in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            let fetchRequest: NSFetchRequest<Review> = Review.fetchRequest()
            
            do {
                let reviews = try context.fetch(fetchRequest)
                
                reviews.forEach { context.delete($0) }
                
                try context.save()
                self.finish()
            } catch {
                self.finish(withError: error)
            }
        }
    }
}
