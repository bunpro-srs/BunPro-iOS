//
//  Created by Andreas Braun on 19.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import Foundation
import ProcedureKit

final class UpdateReviewsProcedure: GroupProcedure {
    let stack: NSPersistentContainer
    let reviews: [BPKReview]

    init(reviews: [BPKReview], stack: NSPersistentContainer = AppDelegate.database.persistantContainer) {
        self.stack = stack
        self.reviews = reviews
        super.init(operations: [])

        self.name = "Update Reviews"

        maxConcurrentOperationCount = 1
    }

    override func execute() {
        guard !isCancelled else { return }

        let batches: [[BPKReview]] = reviews.chunked(into: 30)

        batches.forEach { self.addChild(ImportReviewsIntoCoreDataProcedure(reviews: $0, stack: self.stack)) }

        super.execute()
    }
}

private final class ImportReviewsIntoCoreDataProcedure: Procedure {
    let stack: NSPersistentContainer
    let reviews: [BPKReview]

    init(reviews: [BPKReview], stack: NSPersistentContainer = AppDelegate.database.persistantContainer) {
        self.stack = stack
        self.reviews = reviews

        super.init()
    }

    override func execute() {
        guard !isCancelled else { return }

        stack.performBackgroundTask { context in
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
