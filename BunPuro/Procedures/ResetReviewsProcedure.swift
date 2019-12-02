//
//  Created by Andreas Braun on 19.08.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import CoreData
import Foundation
import ProcedureKit

final class ResetReviewsProcedure: Procedure {
    let stack: NSPersistentContainer

    init(stack: NSPersistentContainer = AppDelegate.database.persistantContainer) {
        self.stack = stack
        super.init()
    }

    override func execute() {
        guard !isCancelled else { return }

        stack.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            let fetchRequest: NSFetchRequest<Review> = Review.fetchRequest()

            do {
                let reviews = try context.fetch(fetchRequest)
                reviews.forEach { context.delete($0) }

                try context.save()
                self.finish()
            } catch {
                self.finish(with: error)
            }
        }
    }
}
