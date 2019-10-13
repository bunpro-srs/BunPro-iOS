//
//  Created by Cihat Gündüz on 24.04.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import Foundation

protocol GrammarFetchedResultsControllerDelegate: AnyObject {
    func fetchedResultsDidChange()
}

class GrammarFetchedResultsController: NSObject {
    private var exampleSentencesFetchedResultsController: NSFetchedResultsController<Sentence>!
    private var readingsFetchedResultsController: NSFetchedResultsController<Link>!

    weak var delegate: GrammarFetchedResultsControllerDelegate?

    func setup(grammar: Grammar) {
        setupSentencesFetchedResultsController(grammar: grammar)
        setupReadingsFetchedResultsController(grammar: grammar)
    }

    func exampleSentence(at indexPath: IndexPath) -> Sentence {
        return exampleSentencesFetchedResultsController.object(at: indexPath)
    }

    func exampleSentencesCount() -> Int {
        return exampleSentencesFetchedResultsController.fetchedObjects?.count ?? 0
    }

    func reading(at indexPath: IndexPath) -> Link {
        return readingsFetchedResultsController.object(at: indexPath)
    }

    func readingsCount() -> Int {
        return readingsFetchedResultsController.fetchedObjects?.count ?? 0
    }

    private func setupSentencesFetchedResultsController(grammar: Grammar) {
        let request: NSFetchRequest<Sentence> = Sentence.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(Sentence.grammar), grammar)

        let sort = NSSortDescriptor(key: #keyPath(Sentence.identifier), ascending: true)
        request.sortDescriptors = [sort]

        request.fetchLimit = AppDelegate.numberOfAllowedSentences

        exampleSentencesFetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: AppDelegate.database.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        exampleSentencesFetchedResultsController?.delegate = self

        do {
            try exampleSentencesFetchedResultsController?.performFetch()
        } catch {
            log.error(error)
        }
    }

    private func setupReadingsFetchedResultsController(grammar: Grammar) {
        let request: NSFetchRequest<Link> = Link.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(Link.grammar), grammar)

        let sort = NSSortDescriptor(key: #keyPath(Link.id), ascending: true)
        request.sortDescriptors = [sort]

        readingsFetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: AppDelegate.database.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        readingsFetchedResultsController?.delegate = self

        do {
            try readingsFetchedResultsController?.performFetch()
        } catch {
            log.error(error)
        }
    }
}

extension GrammarFetchedResultsController: NSFetchedResultsControllerDelegate {
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        delegate?.fetchedResultsDidChange()
    }
}
