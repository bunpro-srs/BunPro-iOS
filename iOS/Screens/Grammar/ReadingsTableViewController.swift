//
//  Created by Andreas Braun on 22.07.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import CoreData
import SafariServices
import UIKit

class ReadingsTableViewController: CoreDataFetchedResultsTableViewController<Link> {
    var grammar: Grammar?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.Grammar.readings

        setupFetchedResultsController()
    }

    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Link> = Link.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "grammar = %@", grammar!)

        let sort = NSSortDescriptor(key: #keyPath(Link.identifier), ascending: true)
        fetchRequest.sortDescriptors = [sort]

        fetchedResultsController = NSFetchedResultsController<Link>(
            fetchRequest: fetchRequest,
            managedObjectContext: AppDelegate.database.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as DetailCell

        let link = fetchedResultsController.object(at: indexPath)

        let font1 = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 12))
        let font2 = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 10))

        cell.attributedName = link
            .site?
            .htmlAttributedString(
                font: font1,
                color: view.tintColor
            )?
            .string
        cell.attributedDescriptionText = link
            .about?
            .htmlAttributedString(font: font2, color: .white)?
            .string
        cell.isDescriptionLabelHidden = false

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url = fetchedResultsController.object(at: indexPath).url else { return }

        let safariViewCtrl = SFSafariViewController(url: url)
        present(safariViewCtrl, animated: true)

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
