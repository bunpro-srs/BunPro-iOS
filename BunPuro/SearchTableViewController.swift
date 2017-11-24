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
        let idSort = NSSortDescriptor(key: #keyPath(Grammar.id), ascending: true)
        fetchRequest.sortDescriptors = [jlptSort, lessonSort, idSort]
        
        let controller = NSFetchedResultsController<Grammar>(fetchRequest: fetchRequest,
                                                             managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
                                                             sectionNameKeyPath: #keyPath(Grammar.lesson.jlpt.name),
                                                             cacheName: nil)
        controller.delegate = self
        
        return controller
    }
    
    private func searchPredicate() -> NSPredicate? {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else { return nil }
        
        let titlePredicate = NSPredicate(format: "%K CONTAINS[cs] %@ ", #keyPath(Grammar.title), searchText)
        let meaningPredicate = NSPredicate(format: "%K CONTAINS[cs] %@ ", #keyPath(Grammar.meaning), searchText)
        
        return NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, meaningPredicate])
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
        
        //loadData()
    }
    
    private func loadData() {
        
//        let stack = AppDelegate.coreDataStack
//
//        Server.updateJLPT { (jlpts, error) in
//            guard error == nil else { return }
//            guard let jlpts = jlpts else { return }
//
//            stack.storeContainer.performBackgroundTask { (context) in
//
//                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
//
//                jlpts.forEach { (jlpt) in
//
//                    let newJPLT = JLPT(context: context)
//
//                    newJPLT.level = Int64(jlpt.level)
//                    newJPLT.name = jlpt.name
//
//                    jlpt.lessons.forEach { (lesson) in
//
//                        let newLesson = Lesson(context: context)
//
//                        newLesson.id = lesson.id
//                        newLesson.order = Int64(lesson.order)
//                        newLesson.jlpt = newJPLT
//
//                        lesson.grammar.forEach { (grammar) in
//
//                            let newGrammar = Grammar(context: context)
//
//                            newGrammar.id = grammar.id
//                            newGrammar.lesson = newLesson
//                            newGrammar.title = grammar.title.htmlAttributedString?.string
//                            newGrammar.meaning = grammar.meaning.htmlAttributedString?.string
//                            newGrammar.caution = grammar.caution.htmlAttributedString?.string
//                            newGrammar.structure = grammar.structure.htmlAttributedString?.string
//
//                            for link in grammar.supplementalLinks {
//
//                                let newLink = Link(context: context)
//                                newLink.id = link.id
//                                newLink.about = link.description
//                                newLink.site = link.site
//                                newLink.url = URL(string: link.link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
//                                newLink.grammar = newGrammar
//                            }
//                        }
//                    }
//                }
//                do {
//                    try context.save()
//                    DispatchQueue.main.async {
//                        stack.save()
//                        self.tableView.reloadData()
//                    }
//                } catch {
//                    print(error)
//                }
//            }
//        }
    }
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath)
        
        updateCell(cell, at: indexPath)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].name ?? "Unknown"
    }
    
    // MARK: - UISearchController

    func updateSearchResults(for searchController: UISearchController) {
        NSFetchedResultsController<Grammar>.deleteCache(withName: nil)
        fetchedResultsController.fetchRequest.predicate = searchPredicate()
        
        try? fetchedResultsController.performFetch()
        
        tableView.reloadData()
    }
    
    private func updateCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let grammar = fetchedResultsController.object(at: indexPath)
        
        cell.textLabel?.text = grammar.title
        cell.detailTextLabel?.text = grammar.meaning
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        switch segueIdentifier(for: identifier) {
        case .showGrammar:
            return tableView.indexPathForSelectedRow != nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segueIdentifier(for: segue) {
        case .showGrammar:
            
            guard let indexPath = tableView.indexPathForSelectedRow else {
                fatalError("IndexPath must be provided")
            }
            
            let destination = segue.destination.content as? GrammarViewController
            destination?.grammar = fetchedResultsController.object(at: indexPath)
        }
    }
}
