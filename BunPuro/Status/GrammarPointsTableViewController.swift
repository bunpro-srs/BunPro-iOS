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
    
    private var reviews: [Review]?
    
    private var activityIndicatorView: UIActivityIndicatorView?
    
    private var willUpdateObserver: NSObjectProtocol?
    private var didUpdateObserver: NSObjectProtocol?
    
    deinit {
        
        print("deinit \(String(describing: self))")
        
        for observer in [didUpdateObserver, willUpdateObserver] {
            
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
        tableView.backgroundView?.addMotion()
        
        guard let lesson = self.lesson else { fatalError("Lesson needs to be provided.") }
        
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicatorView?.hidesWhenStopped = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicatorView!)
        
        willUpdateObserver = NotificationCenter.default.addObserver(
            forName: .BunProWillBeginUpdating,
            object: nil,
            queue: OperationQueue.main) { [weak self] (_) in
                self?.activityIndicatorView?.startAnimating()
        }
        
        didUpdateObserver = NotificationCenter.default.addObserver(
            forName: .BunProDidEndUpdating,
            object: nil,
            queue: OperationQueue.main) { [weak self] (_) in
                self?.updateReviews()
                self?.tableView.reloadData()
                
                self?.activityIndicatorView?.stopAnimating()
        }
        
        updateReviews()
        
        let request: NSFetchRequest<Grammar> = Grammar.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(Grammar.lesson), lesson)
        
        let sort = NSSortDescriptor(key: #keyPath(Grammar.identifier), ascending: true)
        request.sortDescriptors = [sort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AppDelegate.coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as GrammarTeaserCell
        
        let point = fetchedResultsController.object(at: indexPath)
        let hasReview = review(for: point)?.complete ?? false
        
        cell.japaneseLabel?.text = point.title
        cell.meaningLabel?.text = point.meaning
        cell.isComplete = hasReview
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let point = fetchedResultsController.object(at: indexPath)
        let review = self.review(for: point)
        let hasReview = review?.complete ?? false
        
        var actions = [UIContextualAction]()
        
        if hasReview {
            let removeReviewAction = UIContextualAction(style: .normal,
                                                        title: NSLocalizedString("review.edit.remove.short", comment: "")) { (action, view, completion) in
                                                            AppDelegate.modifyReview(.remove(review!.identifier))
                                                            
                                                            completion(true)
            }
            
            removeReviewAction.backgroundColor = .red
            
            let resetReviewAction = UIContextualAction(style: .normal,
                                                       title: NSLocalizedString("review.edit.reset.short", comment: "")) { (action, view, completion) in
                                                        AppDelegate.modifyReview(.reset(review!.identifier))
                                                        
                                                        completion(true)
            }
            
            resetReviewAction.backgroundColor = .purple
            
            actions.append(removeReviewAction)
            actions.append(resetReviewAction)
        } else {
            let addToReviewAction = UIContextualAction(style: UIContextualAction.Style.normal,
                                                       title: NSLocalizedString("review.edit.add.short", comment: "")) { (action, view, completion) in
                                                        AppDelegate.modifyReview(.add(point.identifier))
                                                        
                                                        completion(true)
            }
            
            actions.append(addToReviewAction)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: actions)
        
        return configuration
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showGrammar:
            guard let cell = sender as? UITableViewCell else { fatalError() }
            guard let indexPath = tableView.indexPath(for: cell) else { fatalError() }
            
            let controller = segue.destination.content as? GrammarViewController
            controller?.grammar = fetchedResultsController.object(at: indexPath)
        }
    }
    
    private func updateReviews() {
        
        guard let grammar = lesson?.grammar?.allObjects as? [Grammar] else { reviews = nil; return }
        
        do {
            reviews = try Review.reviews(for: grammar)
        } catch {
            
            print(error)
            reviews = nil
        }
    }
    
    private func review(for grammar: Grammar) -> Review? {
        
        return reviews?.first(where: { $0.grammarIdentifier == grammar.identifier })
    }
}
