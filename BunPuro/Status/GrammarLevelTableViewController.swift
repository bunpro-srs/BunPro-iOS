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

class GrammarLevelTableViewController: CoreDataFetchedResultsTableViewController<Lesson>, SegueHandler {

    enum SegueIdentifier: String {
        case showGrammarLevel
    }
    
    var level: Int = 5
    
    private var didUpdateObserver: NSObjectProtocol?
    
    deinit {
        
        print("deinit \(String(describing: self))")
        
        for observer in [didUpdateObserver] {
            
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let backgroundImageView = UIImageView(image: #imageLiteral(resourceName: "background"))
        backgroundImageView.contentMode = .scaleAspectFill
        
        tableView.backgroundView = backgroundImageView
        
        didUpdateObserver = NotificationCenter.default.addObserver(
            forName: .BunProDidEndUpdating,
            object: nil,
            queue: OperationQueue.main) { [weak self] (_) in
                
                self?.tableView.reloadData()
        }
        
        let request: NSFetchRequest<Lesson> = Lesson.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %d", #keyPath(Lesson.jlpt.level), level)
        
        let sort = NSSortDescriptor(key: #keyPath(Lesson.order), ascending: true)
        request.sortDescriptors = [sort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AppDelegate.coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as JLPTProgressTableViewCell

        let lesson = fetchedResultsController.object(at: indexPath)
        
        let progress = lesson.progress
        let completed = Int(Float(lesson.grammar?.count ?? 0) * progress)
        
        cell.titleLabel?.text = String.localizedStringWithFormat(NSLocalizedString("level.number", comment: "Level in a JLPT"), indexPath.row + 1)
        cell.subtitleLabel?.text = "\(completed) / \(lesson.grammar?.count ?? 0)"
        
        cell.setProgress(progress, animated: false)
        
        return cell
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showGrammarLevel:
            guard let cell = sender as? JLPTProgressTableViewCell else { fatalError("A cell is needed.") }
            guard let indexPath = tableView.indexPath(for: cell) else { fatalError("An index path is needed.") }
            
            let destination = segue.destination.content as? GrammarPointsTableViewController
            destination?.title = cell.titleLabel?.text
            destination?.lesson = fetchedResultsController.object(at: indexPath)
        }
    }
}
