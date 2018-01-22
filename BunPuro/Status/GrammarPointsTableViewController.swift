//
//  GrammarPointsTableViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import BunPuroKit
import CoreData

class GrammarPointsTableViewController: CoreDataFetchedResultsTableViewController<Grammar>, SegueHandler {

    enum SegueIdentifier: String {
        case showGrammar
    }
    
    var lesson: Lesson?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let lesson = self.lesson else { fatalError("Lesson needs to be provided.") }
        
        let request: NSFetchRequest<Grammar> = Grammar.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(Grammar.lesson), lesson)
        
        let sort = NSSortDescriptor(key: #keyPath(Grammar.identifier), ascending: true)
        request.sortDescriptors = [sort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AppDelegate.coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath)
        
        let point = fetchedResultsController.object(at: indexPath)
        
        cell.textLabel?.text = point.title
        cell.detailTextLabel?.text = point.meaning

        return cell
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showGrammar:
            if let indexPath = tableView.indexPathForSelectedRow {
                let controller = segue.destination.content as? GrammarViewController
                controller?.grammar = fetchedResultsController.object(at: indexPath)
            }
        }
    }
}
