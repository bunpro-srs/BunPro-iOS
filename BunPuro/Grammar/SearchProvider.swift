//
//  Created by Andreas Braun on 01.12.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import CoreData
import UIKit

enum SearchScope: Int {
    case all
    case unlearned
    case learned
}

enum SearchSectionMode {
    case byDifficulty
    case byLevel(Int)
}

protocol SearchProvider: AnyObject {
    var sectionMode: SearchSectionMode { get set }
    var scope: SearchScope { get set }
    var searchText: String? { get set }

    func reload()
}

protocol GrammarFetchedResultsControllerProvider: AnyObject {
    var grammarFetchedResultsController: NSFetchedResultsController<Grammar>! { get set }
}

protocol ReviewsFetchedResultsControllerProvider: AnyObject {
    var reviewsFetchedResultsController: NSFetchedResultsController<Review>! { get set }
}

protocol SearchDataSource: SearchProvider, GrammarFetchedResultsControllerProvider, ReviewsFetchedResultsControllerProvider,
    UITableViewDataSource, NSFetchedResultsControllerDelegate {
    // Nothing to implement
}

extension SearchProvider
    where Self: GrammarFetchedResultsControllerProvider,
    Self: ReviewsFetchedResultsControllerProvider,
    Self: NSFetchedResultsControllerDelegate {
    func jlptLevel(for section: Int) -> String? {
        grammarFetchedResultsController?.sections?[section].name
    }

    func grammar(at indexPath: IndexPath) -> Grammar {
        grammarFetchedResultsController.object(at: indexPath)
    }

    func grammar(for jlptLevel: String) -> [Grammar] {
        switch sectionMode {
        case .byDifficulty:
            return grammarFetchedResultsController.fetchedObjects?.filter { $0.level == jlptLevel } ?? []

        case .byLevel:
            return grammarFetchedResultsController.fetchedObjects?.filter { $0.lessonIdentifier == jlptLevel } ?? []
        }
    }

    func currentLevel(for section: Int) -> Int {
        guard let name = jlptLevel(for: section) else { return 0 }
        return correctLevel(from: name)
    }

    func correctLevel(_ level: Int) -> Int {
        let mod = level % 10
        return mod == 0 ? 10 : mod
    }

    func correctLevel(from name: String) -> Int {
        let name = name.replacingOccurrences(of: "JLPT", with: "")
        let level = Int(name) ?? 0

        return correctLevel(level)
    }

    func performSearchQuery(scope: SearchScope, searchText: String?) {
        self.scope = scope
        self.searchText = searchText

        NSFetchedResultsController<Grammar>.deleteCache(withName: nil)

        grammarFetchedResultsController = newGrammarFetchedResultsController(scope: scope, searchText: searchText)

        do {
            try grammarFetchedResultsController.performFetch()

            reload()
        } catch {
            log.error(error.localizedDescription)
        }
    }

    func newGrammarFetchedResultsController(scope: SearchScope, searchText: String?) -> NSFetchedResultsController<Grammar>? {
        let fetchRequest: NSFetchRequest<Grammar> = Grammar.fetchRequest()

        switch sectionMode {
        case .byDifficulty:
            fetchRequest.predicate = predicate(scope: scope, searchText: searchText)

        case let .byLevel(level):
            if let searchPredicate = predicate(scope: scope, searchText: searchText) {
                fetchRequest.predicate = NSCompoundPredicate(
                    andPredicateWithSubpredicates: [
                        searchPredicate,
                        NSPredicate(format: "%K == %@", #keyPath(Grammar.level), "JLPT\(level)")
                    ]
                )
            } else {
                fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Grammar.level), "JLPT\(level)")
            }
        }

        fetchRequest.fetchBatchSize = 15

        let jlptSort = NSSortDescriptor(key: #keyPath(Grammar.level), ascending: false)
        let lessonSort = NSSortDescriptor(key: #keyPath(Grammar.lessonIdentifier), ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
        let idSort = NSSortDescriptor(key: #keyPath(Grammar.identifier), ascending: true)
        fetchRequest.sortDescriptors = [jlptSort, lessonSort, idSort]

        let sectionKeyPath: String

        switch sectionMode {
        case .byDifficulty:
            sectionKeyPath = #keyPath(Grammar.level)

        case .byLevel:
            sectionKeyPath = #keyPath(Grammar.lessonIdentifier)
        }
        let controller = NSFetchedResultsController<Grammar>(
            fetchRequest: fetchRequest,
            managedObjectContext: AppDelegate.database.viewContext,
            sectionNameKeyPath: sectionKeyPath,
            cacheName: nil
        )

        controller.delegate = self

        return controller
    }

    func newReviewsFetchedResultsController() -> NSFetchedResultsController<Review> {
        let fetchRequest: NSFetchRequest<Review> = Review.fetchRequest()

        let sort = NSSortDescriptor(key: #keyPath(Review.identifier), ascending: true)
        fetchRequest.sortDescriptors = [sort]

        let controller = NSFetchedResultsController<Review>(
            fetchRequest: fetchRequest,
            managedObjectContext: AppDelegate.database.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        controller.delegate = self

        return controller
    }

    private func predicate(scope: SearchScope, searchText: String?) -> NSPredicate? {
        guard let searchText = searchText, !searchText.isEmpty else {
            switch scope {
            case .all:
                return nil

            case .learned:
                let reviewIdentifiers = (reviewsFetchedResultsController.fetchedObjects ?? []).compactMap { $0.grammarIdentifier }
                let identifierPredicate = NSPredicate(format: "%K IN %@", #keyPath(Grammar.identifier), reviewIdentifiers)
                return identifierPredicate

            case .unlearned:
                let reviewIdentifiers = (reviewsFetchedResultsController.fetchedObjects ?? []).compactMap { $0.grammarIdentifier }
                let identifierPredicate = NSPredicate(format: "NOT (%K IN %@)", #keyPath(Grammar.identifier), reviewIdentifiers)
                return identifierPredicate
            }
        }

        let titlePredicate = NSPredicate(format: "%K CONTAINS[cs] %@ ", #keyPath(Grammar.title), searchText)
        let meaningPredicate = NSPredicate(format: "%K CONTAINS[cs] %@ ", #keyPath(Grammar.meaning), searchText)
        let yomikataPredicate = NSPredicate(format: "%K CONTAINS[cs] %@ ", #keyPath(Grammar.yomikata), searchText)

        switch scope {
        case .all:
            return NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, meaningPredicate, yomikataPredicate])

        case .learned:
            let reviewIdentifiers = (reviewsFetchedResultsController.fetchedObjects ?? []).compactMap { $0.grammarIdentifier }

            let identifierPredicate = NSPredicate(format: "%K IN %@", #keyPath(Grammar.identifier), reviewIdentifiers)

            return NSCompoundPredicate(
                andPredicateWithSubpredicates: [
                    identifierPredicate,
                    NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, meaningPredicate, yomikataPredicate])
                ]
            )

        case .unlearned:
            let reviewIdentifiers = (reviewsFetchedResultsController.fetchedObjects ?? []).compactMap { $0.grammarIdentifier }

            let identifierPredicate = NSPredicate(format: "NOT (%K IN %@)", #keyPath(Grammar.identifier), reviewIdentifiers)

            return NSCompoundPredicate(
                andPredicateWithSubpredicates: [
                    identifierPredicate,
                    NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, meaningPredicate, yomikataPredicate])
                ]
            )
        }
    }
}
