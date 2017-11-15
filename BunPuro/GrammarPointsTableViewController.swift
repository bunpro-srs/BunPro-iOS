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

class GrammarPointsTableViewController: UITableViewController {

    var lesson: Lesson?
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Grammar> = {
        
        guard let lesson = self.lesson else { fatalError("Lesson needs to be provided.") }
        
        let request: NSFetchRequest<Grammar> = Grammar.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(Grammar.lesson), lesson)
        
        let sort = NSSortDescriptor(key: #keyPath(Grammar.id), ascending: true)
        request.sortDescriptors = [sort]
        
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: AppDelegate.coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath)
        
        let point = fetchedResultsController.object(at: indexPath)
        
        cell.textLabel?.text = point.title
        cell.detailTextLabel?.text = point.meaning

        return cell
    }
}
