//
//  SearchTableViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import BunPuroKit
import CoreData

final class SearchTableViewController: CoreDataFetchedResultsTableViewController<Grammar>, SegueHandler, UISearchResultsUpdating, UISearchBarDelegate {
    
    enum SegueIdentifier: String {
        case showGrammar
    }
    
    private var searchController: UISearchController!
    
    private func newFetchedResultsController() -> NSFetchedResultsController<Grammar>? {
        let fetchRequest: NSFetchRequest<Grammar> = Grammar.fetchRequest()
        
        fetchRequest.predicate = searchPredicate()
        
        let jlptSort = NSSortDescriptor(key: #keyPath(Grammar.level), ascending: false)
        let lessonSort = NSSortDescriptor(key: #keyPath(Grammar.lessonIdentifier), ascending: true)
        let idSort = NSSortDescriptor(key: #keyPath(Grammar.identifier), ascending: true)
        fetchRequest.sortDescriptors = [jlptSort, lessonSort, idSort]
        
        let controller = NSFetchedResultsController<Grammar>(fetchRequest: fetchRequest,
                                                             managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
                                                             sectionNameKeyPath: #keyPath(Grammar.level),
                                                             cacheName: nil)
        controller.delegate = self
        
        return controller
    }
    
    private var reviewsFetchedResultsController: NSFetchedResultsController<Review> = {
        
        let fetchRequest: NSFetchRequest<Review> = Review.fetchRequest()
        
        let sort = NSSortDescriptor(key: #keyPath(Review.identifier), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        let controller = NSFetchedResultsController<Review>(fetchRequest: fetchRequest,
                                                             managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
                                                             sectionNameKeyPath: nil,
                                                             cacheName: nil)
        
        return controller
    }()
    
    private func searchPredicate() -> NSPredicate? {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            
            switch searchController.searchBar.selectedScopeButtonIndex {
            case 1:
                let reviewIdentifiers = (reviewsFetchedResultsController.fetchedObjects ?? []).compactMap { return $0.grammarIdentifier }
                let identifierPredicate = NSPredicate(format: "NOT (%K IN %@)", #keyPath(Grammar.identifier), reviewIdentifiers)
                return identifierPredicate
            case 2:
                let reviewIdentifiers = (reviewsFetchedResultsController.fetchedObjects ?? []).compactMap { return $0.grammarIdentifier }
                let identifierPredicate = NSPredicate(format: "%K IN %@", #keyPath(Grammar.identifier), reviewIdentifiers)
                return identifierPredicate
            default:
                return nil
            }
        }
        
        let titlePredicate = NSPredicate(format: "%K CONTAINS[cs] %@ ", #keyPath(Grammar.title), searchText)
        let meaningPredicate = NSPredicate(format: "%K CONTAINS[cs] %@ ", #keyPath(Grammar.meaning), searchText)
        
        switch searchController.searchBar.selectedScopeButtonIndex {
        case 1:
            let reviewIdentifiers = (reviewsFetchedResultsController.fetchedObjects ?? []).compactMap { return $0.grammarIdentifier }
            
            let identifierPredicate = NSPredicate(format: "NOT (%K IN %@)", #keyPath(Grammar.identifier), reviewIdentifiers)
            
            return NSCompoundPredicate(andPredicateWithSubpredicates: [identifierPredicate, NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, meaningPredicate])])
        case 2:
            let reviewIdentifiers = (reviewsFetchedResultsController.fetchedObjects ?? []).compactMap { return $0.grammarIdentifier }
            
            let identifierPredicate = NSPredicate(format: "%K IN %@", #keyPath(Grammar.identifier), reviewIdentifiers)
            
            return NSCompoundPredicate(andPredicateWithSubpredicates: [identifierPredicate, NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, meaningPredicate])])
        default:
            return NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, meaningPredicate])
        }
    }
    
    deinit {
        
        print("deinit \(String(describing: self))")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = UIColor(named: "ModernDark")
        
        definesPresentationContext = true
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        
        navigationItem.searchController = searchController
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.setShowsCancelButton(false, animated: false)
        searchController.searchBar.delegate = self
        searchController.searchBar.keyboardAppearance = .dark
        searchController.searchBar.sizeToFit()
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchController.searchBar.placeholder = NSLocalizedString("search.grammar.placeholder", comment: "Search grammar placeholder")
        searchController.searchBar.barStyle = .black
        
        searchController.searchBar.scopeButtonTitles = [
            NSLocalizedString("search.grammar.scope.all", comment: ""),
            NSLocalizedString("search.grammar.scope.unlearned", comment: ""),
            NSLocalizedString("search.grammar.scope.learned", comment: "")
        ]
        
        fetchedResultsController = newFetchedResultsController()
        
        reviewsFetchedResultsController.delegate = self
        
        do {
            try reviewsFetchedResultsController.performFetch()
        } catch {
            print(error)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchController.searchBar.setShowsCancelButton(false, animated: false)
    }
    
    private func review(for grammar: Grammar) -> Review? {
        return reviewsFetchedResultsController.fetchedObjects?.first(where: { $0.grammarIdentifier == grammar.identifier })
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as GrammarTeaserCell
        
        updateCell(cell, at: indexPath)

        return cell
    }
    
    private func progress(count: Int, max: Int) -> Float {
        guard max > 0 else { return 0 }
        return Float(count) / Float(max)
    }
    
    private func correctLevel(_ level: Int) -> Int {
        let mod = level % 10
        return mod == 0 ? 10 : mod
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let name = fetchedResultsController?.sections?[section].name else { return nil }
        
        let cell = tableView.dequeueReusableCell() as JLPTProgressTableViewCell
        
        let grammarPoints = fetchedResultsController.fetchedObjects?.filter({ $0.level == name }) ?? []
        let grammarCount = grammarPoints.count
        let finishedGrammarCount = grammarPoints.filter({ $0.review?.complete == true }).count
        
        cell.titleLabel.text = name.replacingOccurrences(of: "JLPT", with: "N")
        cell.subtitleLabel?.text = "\(finishedGrammarCount) / \(grammarCount)"
        cell.setProgress(progress(count: finishedGrammarCount, max: grammarCount), animated: false)
        
        return cell.contentView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 66
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController?.sections?.compactMap { section in
            let name = section.name.replacingOccurrences(of: "JLPT", with: "")
            return name
        }
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
    
    // MARK: - UISearchController

    func updateSearchResults(for searchController: UISearchController) {
        
        NSFetchedResultsController<Grammar>.deleteCache(withName: nil)
        fetchedResultsController.fetchRequest.predicate = searchPredicate()
        
        try? fetchedResultsController.performFetch()
        
        tableView.reloadData()
    }
    
    private func updateCell(_ cell: GrammarTeaserCell, at indexPath: IndexPath) {
        let grammar = fetchedResultsController.object(at: indexPath)
        
        cell.japaneseLabel?.text = grammar.title
        cell.meaningLabel?.text = grammar.meaning
        
        let hasReview = review(for: grammar)?.complete ?? false
        cell.isComplete = hasReview
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segueIdentifier(for: segue) {
        case .showGrammar:
            
            guard let cell = sender as? UITableViewCell else { fatalError() }
            guard let indexPath = tableView.indexPath(for: cell) else {
                fatalError("IndexPath must be provided")
            }
            
            let destination = segue.destination.content as? GrammarViewController
            destination?.grammar = fetchedResultsController.object(at: indexPath)
        }
    }
    
    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if controller == fetchedResultsController {
            super.controller(controller, didChange: anObject, at: indexPath, for: type, newIndexPath: newIndexPath)
        } else if controller == reviewsFetchedResultsController, let visibleRowIndexpaths = tableView.indexPathsForVisibleRows {
            tableView.reloadRows(at: visibleRowIndexpaths, with: .automatic)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        updateSearchResults(for: searchController)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        
        searchController.searchBar.setShowsCancelButton(false, animated: false)
        searchController.searchBar.sizeToFit()

        return true
    }
}
