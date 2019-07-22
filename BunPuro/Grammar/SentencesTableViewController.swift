//
//  Created by Andreas Braun on 21.07.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import CoreData
import Protocols
import UIKit

class SentencesTableViewController: CoreDataFetchedResultsTableViewController<Sentence> {
    var grammar: Grammar?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupFetchedResultsController()
    }

    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Sentence> = Sentence.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "grammar = %@", grammar!)

        let sort = NSSortDescriptor(key: #keyPath(Sentence.identifier), ascending: true)
        fetchRequest.sortDescriptors = [sort]

        fetchedResultsController = NSFetchedResultsController<Sentence>(
            fetchRequest: fetchRequest,
            managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as DetailCell

        // Configure the cell...

        return cell
    }
}
