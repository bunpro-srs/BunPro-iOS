//
//  Created by Cihat Gündüz on 24.04.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import Foundation

protocol StatusFetchedResultsControllerDelegate: AnyObject {
    func fetchedResultsAccountDidChange(account: Account?)
    func fetchedResultsReviewsDidChange(reviews: [Review]?)
}

class StatusFetchedResultsController: NSObject {
    typealias LevelMetric = (complete: Int, max: Int, progress: Float)

    private var userFetchedResultsController: NSFetchedResultsController<Account>?
    private var reviewsFetchedResultsController: NSFetchedResultsController<Review>?

    weak var delegate: StatusFetchedResultsControllerDelegate?

    func setup() {
        setupUserFetchedResultsController()
        setupReviewsFetchedResultsController()
    }

    func metricForLevel(_ level: Int) -> LevelMetric {
        let completeFetchRequest: NSFetchRequest<Grammar> = Grammar.fetchRequest()
        completeFetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(Grammar.level), "JLPT\(level)")

        do {
            let grammarPoints = try AppDelegate.database.viewContext.fetch(completeFetchRequest)

            let complete = grammarPoints.filter { $0.review?.complete == true }.count
            let max = grammarPoints.count

            var progress: Float = 0.0

            if max > 0, max >= complete {
                progress = Float(complete) / Float(max)
            }

            return (complete, max, progress)
        } catch {
            return (0, 0, 0.0)
        }
    }

    private func setupUserFetchedResultsController() {
        let request: NSFetchRequest<Account> = Account.fetchRequest()

        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Account.name), ascending: true)]
        request.fetchLimit = 1

        userFetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: AppDelegate.database.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        userFetchedResultsController?.delegate = self

        do {
            try userFetchedResultsController?.performFetch()
        } catch {
            log.error(error)
        }
    }

    private func setupReviewsFetchedResultsController() {
        let request: NSFetchRequest<Review> = Review.fetchRequest()

        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Review.updatedDate), ascending: true)]
        request.predicate = NSPredicate(
            format: "%K < %@ AND %K == true",
            #keyPath(Review.nextReviewDate),
            Date().tomorrow.tomorrow.nextMidnight as NSDate,
            #keyPath(Review.complete)
        )
        request.fetchBatchSize = 25

        reviewsFetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: AppDelegate.database.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        reviewsFetchedResultsController?.delegate = self

        do {
            try reviewsFetchedResultsController?.performFetch()
        } catch {
            log.error(error)
        }
    }
}

extension StatusFetchedResultsController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == userFetchedResultsController, let account = userFetchedResultsController?.fetchedObjects?.first {
            delegate?.fetchedResultsAccountDidChange(account: account)
        } else if controller == reviewsFetchedResultsController {
            delegate?.fetchedResultsReviewsDidChange(reviews: reviewsFetchedResultsController?.fetchedObjects)
        }
    }
}
