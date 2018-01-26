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

class SearchTableViewController: CoreDataFetchedResultsTableViewController<Grammar>, SegueHandler, UISearchResultsUpdating {
    
    enum SegueIdentifier: String {
        case showGrammar
    }
    
    private var searchController: UISearchController!
    
    private func newFetchedResultsController() -> NSFetchedResultsController<Grammar>? {
        let fetchRequest: NSFetchRequest<Grammar> = Grammar.fetchRequest()
        
        fetchRequest.predicate = searchPredicate()
        
        let jlptSort = NSSortDescriptor(key: #keyPath(Grammar.lesson.jlpt.level), ascending: false)
        let lessonSort = NSSortDescriptor(key: #keyPath(Grammar.lesson.order), ascending: true)
        let idSort = NSSortDescriptor(key: #keyPath(Grammar.identifier), ascending: true)
        fetchRequest.sortDescriptors = [jlptSort, lessonSort, idSort]
        
        let controller = NSFetchedResultsController<Grammar>(fetchRequest: fetchRequest,
                                                             managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
                                                             sectionNameKeyPath: #keyPath(Grammar.lesson.jlpt.name),
                                                             cacheName: nil)
        controller.delegate = self
        
        return controller
    }
    
    private var reviewsFetchedResultsController: NSFetchedResultsController<Review> = {
        
        let fetchRequest: NSFetchRequest<Review> = Review.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "%K = true", #keyPath(Review.complete))
        
        let sort = NSSortDescriptor(key: #keyPath(Review.identifier), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        let controller = NSFetchedResultsController<Review>(fetchRequest: fetchRequest,
                                                             managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
                                                             sectionNameKeyPath: nil,
                                                             cacheName: nil)
        
        return controller
    }()
    
    private func searchPredicate() -> NSPredicate? {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else { return nil }
        
        let titlePredicate = NSPredicate(format: "%K CONTAINS[cs] %@ ", #keyPath(Grammar.title), searchText)
        let meaningPredicate = NSPredicate(format: "%K CONTAINS[cs] %@ ", #keyPath(Grammar.meaning), searchText)
        
        return NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, meaningPredicate])
    }
    
    deinit {
        
        print("deinit \(String(describing: self))")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        definesPresentationContext = true
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        
        searchController.searchBar.showsCancelButton = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        navigationItem.titleView = searchController.searchBar
        searchController.searchBar.sizeToFit()
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchController.searchBar.placeholder = NSLocalizedString("search.grammar.placeholder", comment: "Search grammar placeholder")
        
        fetchedResultsController = newFetchedResultsController()
        
        do {
            try reviewsFetchedResultsController.performFetch()
        } catch {
            print(error)
        }
        
        loadData()
    }
    
    private func loadData() {
        
        self.navigationItem.prompt = "Updating..."
        
        let updateProcedure = UpdateGrammarProcedure(presentingViewController: self)
        
        updateProcedure.completionBlock = {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.navigationItem.prompt = nil
            }
        }
        
        Server.add(procedure: updateProcedure)
    }
    
    private func review(for grammar: Grammar) -> Review? {
        
        return reviewsFetchedResultsController.fetchedObjects?.first(where: { $0.grammarIdentifier == grammar.identifier && $0.complete })
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as GrammarTeaserCell
        
        updateCell(cell, at: indexPath)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].name ?? "Unknown"
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return ["5", "4", "3", "2", "1"]
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
        cell.isComplete = review(for: grammar) != nil
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
}
