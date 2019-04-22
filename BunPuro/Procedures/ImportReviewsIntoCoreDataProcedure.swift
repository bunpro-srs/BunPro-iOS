//
//  Created by Andreas Braun on 19.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import BunPuroKit
import CoreData
import Foundation
import ProcedureKit

final class ImportReviewsIntoCoreDataProcedure: Procedure {
    let stack: CoreDataStack
    let reviews: [BPKReview]

    init(reviews: [BPKReview], stack: CoreDataStack = AppDelegate.coreDataStack) {
        self.stack = stack
        self.reviews = reviews

        super.init()
    }

    override func execute() {
        guard !isCancelled else { return }

        stack.storeContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            self.reviews.forEach { Review(review: $0, context: context) }

            do {
                try context.save()
                self.finish()
            } catch {
                self.finish(with: error)
            }
        }
    }
}
