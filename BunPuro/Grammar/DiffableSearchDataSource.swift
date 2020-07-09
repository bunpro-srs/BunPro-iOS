//
//  Created by Andreas Braun on 29.11.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import CoreData
import UIKit

@available(iOS 13.0, *)
final class DiffableSearchDataSource: UITableViewDiffableDataSource<String, NSManagedObjectID>,
    SearchDataSource {
    typealias Scope = SearchScope
    typealias SectionMode = SearchSectionMode

    var sectionMode: SectionMode = .byDifficulty
    var scope: Scope = .all
    var searchText: String?

    var grammarFetchedResultsController: NSFetchedResultsController<Grammar>!
    var reviewsFetchedResultsController: NSFetchedResultsController<Review>!

    override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<String, NSManagedObjectID>.CellProvider) {
        super.init(tableView: tableView, cellProvider: cellProvider)

        grammarFetchedResultsController = self.newGrammarFetchedResultsController(scope: .all, searchText: nil)
        reviewsFetchedResultsController = self.newReviewsFetchedResultsController()

        do {
            try reviewsFetchedResultsController.performFetch()
        } catch {
            log.error(error.localizedDescription)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        grammarFetchedResultsController?.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        grammarFetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
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

    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        switch sectionMode {
        case .byDifficulty:
            return grammarFetchedResultsController.sections?.firstIndex { $0.name == "JLPT\(title)" } ?? 0

        case .byLevel:
            return grammarFetchedResultsController.sections?.firstIndex { String(self.correctLevel(from: $0.name)) == title } ?? 0
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        if controller == grammarFetchedResultsController {
            apply(snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>, animatingDifferences: false)
        } else {
            var snapshot = self.snapshot()
            snapshot.reloadSections(snapshot.sectionIdentifiers)
            apply(snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>, animatingDifferences: false)
        }
    }

    func reload() {
        // Nothing to do here
    }
}
