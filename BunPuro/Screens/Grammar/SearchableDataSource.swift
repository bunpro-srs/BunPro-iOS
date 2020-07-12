//
//  Created by Andreas Braun on 01.12.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

// This Data Source is only here for iOS 11 and iOS 12 support and will be removed at some point.

import CoreData
import UIKit

final class SearchableDataSource: NSObject,
    SearchDataSource {
    typealias Scope = SearchScope
    typealias SectionMode = SearchSectionMode

    var sectionMode: SectionMode = .byDifficulty
    var scope: Scope = .all
    var searchText: String?

    var grammarFetchedResultsController: NSFetchedResultsController<Grammar>!
    var reviewsFetchedResultsController: NSFetchedResultsController<Review>!

    var tableView: UITableView!

    init(tableView: UITableView) {
        self.tableView = tableView

        super.init()

        grammarFetchedResultsController = self.newGrammarFetchedResultsController(scope: .all, searchText: nil)
        reviewsFetchedResultsController = self.newReviewsFetchedResultsController()

        do {
            try reviewsFetchedResultsController.performFetch()
        } catch {
            log.error(error.localizedDescription)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        grammarFetchedResultsController?.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        grammarFetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        grammarFetchedResultsController?.sections?.compactMap { section in
            let name = section.name.replacingOccurrences(of: "JLPT", with: "")

            switch self.sectionMode {
            case .byDifficulty:
                return name

            case .byLevel:
                let level = Int(name) ?? 0

                return String(correctLevel(level))
            }
        }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        switch sectionMode {
        case .byDifficulty:
            return grammarFetchedResultsController.sections?.firstIndex { $0.name == "JLPT\(title)" } ?? 0

        case .byLevel:
            return grammarFetchedResultsController.sections?.firstIndex { String(self.correctLevel(from: $0.name)) == title } ?? 0
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let grammar = self.grammar(at: indexPath)
        let cell = tableView.dequeueReusableCell(for: indexPath) as GrammarTeaserCell

        cell.update(with: grammar)

        return cell
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType
    ) {
        tableView.reloadData()
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        if controller == reviewsFetchedResultsController {
            //
            if let review = anObject as? Review,
                let grammar = grammarFetchedResultsController.fetchedObjects?.first(where: { $0.identifier == review.grammarIdentifier }),
                let indexPath = grammarFetchedResultsController.indexPath(forObject: grammar),
                let cell = tableView.cellForRow(at: indexPath) as? GrammarTeaserCell {
                cell.update(with: grammar)
            }
        } else if controller == grammarFetchedResultsController {
            switch type {
            case .insert:
                if let indexPath = newIndexPath {
                    tableView.insertRows(at: [indexPath], with: .fade)
                }

            case .delete:
                if let indexPath = indexPath {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }

            case .update:
                if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? GrammarTeaserCell {
                    cell.update(with: grammar(at: indexPath))
                }

            case .move:
                if let indexPath = indexPath {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }

                if let newIndexPath = newIndexPath {
                    tableView.insertRows(at: [newIndexPath], with: .fade)
                }
            @unknown default:
                tableView.reloadData()
            }
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    func reload() {
        tableView.reloadData()
    }
}
