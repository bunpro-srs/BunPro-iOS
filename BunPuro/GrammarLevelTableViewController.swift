//
//  GrammarLevelTableViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import BunPuroKit
import CoreData

class GrammarLevelTableViewController: UITableViewController {

    var level: Int = 5
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Lesson> = {
        let request: NSFetchRequest<Lesson> = Lesson.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %d", #keyPath(Lesson.jlpt.level), level)
        
        let sort = NSSortDescriptor(key: #keyPath(Lesson.order), ascending: true)
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

        let lesson = fetchedResultsController.object(at: indexPath)
        
        cell.textLabel?.text = "\(lesson.order)"
        cell.detailTextLabel?.text = "\(lesson.grammar?.count ?? 0)"

        return cell
    }
}

extension GrammarLevelTableViewController: SegueHandler {
    
    enum SegueIdentifier: String {
        case showGrammarLevel
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showGrammarLevel:
            guard let indexPath = tableView.indexPathForSelectedRow else { fatalError("An index path is needed.") }
            
            let destination = segue.destination.content as? GrammarPointsTableViewController
            destination?.title = "\(indexPath.row + 1)"
            destination?.lesson = fetchedResultsController.object(at: indexPath)
        }
    }
}
