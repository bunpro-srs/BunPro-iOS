//
//  Created by Andreas Braun on 11.09.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import Foundation
import ProcedureKit

protocol DatabaseHandler {
    func updateAccount(_ account: BPKAccount)
    func updateGrammar(_ grammar: [BPKGrammar])
    func updateReviews(_ reviews: [BPKReview])
}

final class Database {
    private let modelName: String

    init(modelName: String) {
        self.modelName = modelName
    }

    lazy var viewContext: NSManagedObjectContext = {
        self.persistantContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        self.persistantContainer.viewContext.automaticallyMergesChangesFromParent = true
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
}

extension Database: DatabaseHandler {
    func updateAccount(_ account: BPKAccount) {
        handler.updateAccount(account)
    }

    func updateGrammar(_ grammar: [BPKGrammar]) {
        handler.updateGrammar(grammar)
    }

    func updateReviews(_ reviews: [BPKReview]) {
        handler.updateReviews(reviews)
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

    func updateAccount(_ account: BPKAccount) {
        let procedure = ImportAccountIntoCoreDataProcedure(account: account, stack: persistantContainer)
        queue.addOperation(procedure)
    }

    func updateGrammar(_ grammar: [BPKGrammar]) {
        let procedure = ImportGrammarPointsIntoCoreDataProcedure(stack: persistantContainer, grammarPoints: grammar)
        procedure.addDidFinishBlockObserver { [weak self] _, _ in
            try? self?.persistantContainer.viewContext.save()
        }
        queue.addOperation(procedure)
    }

    func updateReviews(_ reviews: [BPKReview]) {
        let procedure = UpdateReviewsProcedure(reviews: reviews, stack: persistantContainer)
        queue.addOperation(procedure)
    }
}

@available(iOS 13, *)
private class CombineDatabase: DatabaseHandler {
    private let persistantContainer: NSPersistentContainer

    init(persistantContainer: NSPersistentContainer) {
        self.persistantContainer = persistantContainer
    }

    func updateAccount(_ account: BPKAccount) {
        persistantContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            context.automaticallyMergesChangesFromParent = true

            _ = Account(account: account, context: context)

            try? context.save()
        }
    }

    func updateGrammar(_ grammar: [BPKGrammar]) {
        let batches = grammar.chunked(into: 40)

        batches.forEach { batch in
            persistantContainer.performBackgroundTask { context in
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                context.automaticallyMergesChangesFromParent = true

                let filteredBatch = batch.filter { $0.level != "0" }

                filteredBatch.forEach { Grammar(grammar: $0, context: context) }

                try? context.save()
            }
        }
    }

    func updateReviews(_ reviews: [BPKReview]) {
        persistantContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            context.automaticallyMergesChangesFromParent = true

            let batches = reviews.chunked(into: 40)

            batches.forEach { batch in
                batch.forEach { Review(review: $0, context: context) }
            }

            try? context.save()
        }
    }
}
