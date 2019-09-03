//
//  Created by Andreas Braun on 22.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import CoreData
import UIKit

class CoreDataFetchedResultsTableViewController<T: NSFetchRequestResult>: UITableViewController, NSFetchedResultsControllerDelegate {
    var fetchedResultsController: NSFetchedResultsController<T>! {
        didSet {
            tableView.dataSource = self
            fetchedResultsController.delegate = self

            do {
                try fetchedResultsController.performFetch()
            } catch {
                log.error(error)
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
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
        tableView.reloadData()
    }
}
