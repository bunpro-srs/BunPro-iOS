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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath)
        
        let link = fetchedResultsController.object(at: indexPath)
        
        cell.textLabel?.text = link.site
        cell.detailTextLabel?.text = link.about
        
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
