//
//  Created by Andreas Braun on 11.09.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import Foundation
import ProcedureKit

protocol DatabaseHandler {
    func updateAccount(_ account: BPKAccount, completion: (() -> Void)?)
    func updateGrammar(_ grammar: [BPKGrammar], completion: (() -> Void)?)
    func updateReviews(_ reviews: [BPKReview], completion: (() -> Void)?)
    func resetReviews()
}

final class Database {
    private let modelName: String

    init(modelName: String) {
        self.modelName = modelName
    }

    lazy var viewContext: NSManagedObjectContext = {
        self.persistantContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        self.persistantContainer.viewContext.automaticallyMergesChangesFromParent = true
        self.persistantContainer.viewContext.shouldDeleteInaccessibleFaults = true
        return self.persistantContainer.viewContext
    }()

    lazy var persistantContainer: NSPersistentContainer = {
        func removeDatabase() throws {
            let contents = try FileManager.default.contentsOfDirectory(atPath: NSPersistentContainer.defaultDirectoryURL().path)

            for name in contents {
                if let url = URL(string: NSPersistentContainer.defaultDirectoryURL().absoluteString + name) {
                    try FileManager.default.removeItem(at: url)
                }
            }
        }

        let container = NSPersistentContainer(name: modelName)

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                do {
                    try removeDatabase()

                    container.loadPersistentStores { _, error in
                        if let error = error as NSError? {
                            log.error("Unresolved error: \(error.userInfo)")
                        }
                    }
                } catch let fileError { // swiftlint:disable:this untyped_error_in_catch
                    log.error("Unresolved error: \(error.userInfo)\n\(fileError)")
                }
            }
        }

        return container
    }()

    fileprivate lazy var handler: DatabaseHandler = {
        if #available(iOS 13, *) {
            return CombineDatabase(persistantContainer: self.persistantContainer)
        } else {
            return PrecedureDatabase(persistantContainer: self.persistantContainer)
        }
    }()

    func save() {
        guard viewContext.hasChanges else { return }

        do {
            try viewContext.save()
        } catch let error as NSError {
            log.error("Unresolved error: \(error.userInfo)")
        }
    }

    func resetReviews() {
        handler.resetReviews()
    }
}

extension Database: DatabaseHandler {
    func updateAccount(_ account: BPKAccount, completion: (() -> Void)?) {
        handler.updateAccount(account, completion: completion)

        if #available(iOS 13.0, *) {
            if UserDefaults.standard.userInterfaceStyle == .bunpro {
                UserDefaults.standard.userInterfaceStyle = .bunpro
            }
        }
    }

    func updateGrammar(_ grammar: [BPKGrammar], completion: (() -> Void)?) {
        handler.updateGrammar(grammar, completion: completion)
    }

    func updateReviews(_ reviews: [BPKReview], completion: (() -> Void)?) {
        handler.updateReviews(reviews, completion: completion)
    }
}

private class PrecedureDatabase: DatabaseHandler {
    private let persistantContainer: NSPersistentContainer
    private let queue: ProcedureQueue

    init(persistantContainer: NSPersistentContainer) {
        self.persistantContainer = persistantContainer
        self.queue = ProcedureQueue()
        self.queue.maxConcurrentOperationCount = 1
    }

    func updateAccount(_ account: BPKAccount, completion: (() -> Void)?) {
        let procedure = ImportAccountIntoCoreDataProcedure(account: account, stack: persistantContainer)
        procedure.addDidFinishBlockObserver { _, _ in
            completion?()
        }
        queue.addOperation(procedure)
    }

    func updateGrammar(_ grammar: [BPKGrammar], completion: (() -> Void)?) {
        let procedure = ImportGrammarPointsIntoCoreDataProcedure(stack: persistantContainer, grammarPoints: grammar)
        procedure.addDidFinishBlockObserver { _, _ in
            completion?()
        }
        queue.addOperation(procedure)
    }

    func updateReviews(_ reviews: [BPKReview], completion: (() -> Void)?) {
        let procedure = UpdateReviewsProcedure(reviews: reviews, stack: persistantContainer)
        procedure.addDidFinishBlockObserver { _, _ in
            completion?()
        }
        queue.addOperation(procedure)
    }

    func resetReviews() {
        queue.addOperation(ResetReviewsProcedure())
    }
}

@available(iOS 13, *)
private class CombineDatabase: DatabaseHandler {
    private let persistantContainer: NSPersistentContainer

    init(persistantContainer: NSPersistentContainer) {
        self.persistantContainer = persistantContainer
    }

    func updateAccount(_ account: BPKAccount, completion: (() -> Void)?) {
        persistantContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            context.undoManager = nil

            context.performAndWait {
                _ = Account(account: account, context: context)

                if context.hasChanges {
                    do {
                        try context.save()
                        context.reset()
                    } catch {
                        log.error(error.localizedDescription)
                    }
                }

                completion?()
            }
        }
    }

    func updateGrammar(_ grammar: [BPKGrammar], completion: (() -> Void)?) {
        let batches = grammar.chunked(into: 60)

        batches.forEach { batch in
            persistantContainer.performBackgroundTask { context in
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                context.undoManager = nil

                let filteredBatch = batch.filter { $0.level != "0" }

                context.performAndWait {
                    filteredBatch.forEach { Grammar(grammar: $0, context: context) }

                    if context.hasChanges {
                        do {
                            try context.save()
                            context.reset()
                        } catch {
                            log.error(error.localizedDescription)
                        }
                    }

                    completion?()
                }
            }
        }
    }

    func updateReviews(_ reviews: [BPKReview], completion: (() -> Void)?) {
        let batches = reviews.chunked(into: 60)

        batches.forEach { batch in
            persistantContainer.performBackgroundTask { context in
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                context.undoManager = nil

                context.performAndWait {
                    batch.forEach { Review(review: $0, context: context) }

                    if context.hasChanges {
                        do {
                            try context.save()
                            context.reset()
                        } catch {
                            log.error(error.localizedDescription)
                        }

                        completion?()
                    }
                }
            }
        }
    }

    func resetReviews() {
        persistantContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            let fetchRequest: NSFetchRequest<Review> = Review.fetchRequest()

            do {
                let reviews = try context.fetch(fetchRequest)
                reviews.forEach { context.delete($0) }

                if context.hasChanges {
                    try context.save()
                    context.reset()
                }
            } catch {
                log.error(error.localizedDescription)
            }
        }
    }
}
