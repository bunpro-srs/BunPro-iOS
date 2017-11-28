//
//  GrammarExampleSentancesViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 23.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import CoreData

class GrammarExampleSentancesViewController: CoreDataFetchedResultsTableViewController<Sentence>, GrammarPresenter {

    var grammar: Grammar?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let grammar = grammar else {
            fatalError("Grammar needs to be provided.")
        }
        
        let request: NSFetchRequest<Sentence> = Sentence.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(Sentence.grammar), grammar)
        
        let sort = NSSortDescriptor(key: #keyPath(Sentence.id), ascending: true)
        request.sortDescriptors = [sort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AppDelegate.coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath)
        
        let sentence = fetchedResultsController.object(at: indexPath)
        
        cell.textLabel?.text = sentence.japanese
        cell.detailTextLabel?.text = sentence.english
        
        return cell
    }
}
