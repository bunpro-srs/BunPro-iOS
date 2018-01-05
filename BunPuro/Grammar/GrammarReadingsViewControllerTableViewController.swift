//
//  GrammarReadingsViewControllerTableViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 22.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import CoreData
import SafariServices

class GrammarReadingsViewControllerTableViewController: CoreDataFetchedResultsTableViewController<Link>, GrammarPresenter {

    var grammar: Grammar?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let grammar = grammar else {
            fatalError("Grammar needs to be provided.")
        }
        
        let request: NSFetchRequest<Link> = Link.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(Link.grammar), grammar)
        
        let sort = NSSortDescriptor(key: #keyPath(Link.id), ascending: true)
        request.sortDescriptors = [sort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AppDelegate.coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath)
        
        let link = fetchedResultsController.object(at: indexPath)
        
        let font1 = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 12))
        let font2 = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 10))
        
        cell.textLabel?.attributedText = link.site?.htmlAttributedString(font: font1)
        cell.detailTextLabel?.attributedText = link.about?.htmlAttributedString(font: font2)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        guard let url = fetchedResultsController.object(at: indexPath).url else { return }
        
        let safariViewController = SFSafariViewController(url: url)

        present(safariViewController, animated: true, completion: nil)
    }
}
