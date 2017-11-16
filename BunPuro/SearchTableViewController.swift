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

class SearchTableViewController: UITableViewController, UISearchResultsUpdating {
    
    private var searchController: UISearchController!
    
    private var fetchedResultsController: NSFetchedResultsController<Grammar>!
    
    private func newFetchedResultsController() -> NSFetchedResultsController<Grammar>? {
        let fetchRequest: NSFetchRequest<Grammar> = Grammar.fetchRequest()
        
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            let titlePredicate = NSPredicate(format: "%K CONTAINS[cs] %@ ", #keyPath(Grammar.title), searchText)
            let meaningPredicate = NSPredicate(format: "%K CONTAINS[cs] %@ ", #keyPath(Grammar.meaning), searchText)
            
            fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, meaningPredicate])
        }
        
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        definesPresentationContext = true
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        
        searchController.searchBar.showsCancelButton = false
        searchController.dimsBackgroundDuringPresentation = false
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        fetchedResultsController = newFetchedResultsController()
        
        performFetch()
        
        loadData()
    }
    
    private func loadData() {
        
        let stack = AppDelegate.coreDataStack

        Server.updateJLPT { (jlpts, error) in
            guard error == nil else { return }
            guard let jlpts = jlpts else { return }
            
            stack.storeContainer.performBackgroundTask { (context) in
                
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                
                jlpts.forEach { (jlpt) in
                    
                    let newJPLT = JLPT(context: context)
                    
                    newJPLT.level = Int64(jlpt.level)
                    newJPLT.name = jlpt.name
                    
                    jlpt.lessons.forEach { (lesson) in
                        
                        let newLesson = Lesson(context: context)
                        
                        newLesson.id = lesson.id
                        newLesson.order = Int64(lesson.order)
                        newLesson.jlpt = newJPLT
                        
                        lesson.grammar.forEach { (grammar) in
                            
                            let newGrammar = Grammar(context: context)
                            
                            newGrammar.id = grammar.id
                            newGrammar.lesson = newLesson
                            newGrammar.title = grammar.title
                            newGrammar.meaning = grammar.meaning
                        }
                    }
                }
                do {
                    try context.save()
                    DispatchQueue.main.async {
                        stack.save()
                        
                        self.performFetch(reload: true)
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
    
    private func performFetch(reload: Bool = false) {
        
        do {
            try fetchedResultsController.performFetch()
            
            if reload { tableView?.reloadData() }
            
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
        
        updateCell(cell, at: indexPath)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].name ?? "Unknown"
    }
    
    // UISearchController

    func updateSearchResults(for searchController: UISearchController) {
        fetchedResultsController = newFetchedResultsController()
        performFetch(reload: true)
    }
    
    private func updateCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let grammar = fetchedResultsController.object(at: indexPath)
        
        cell.textLabel?.text = grammar.title
        cell.detailTextLabel?.text = grammar.meaning
    }
}

extension SearchTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            guard let cell = tableView.cellForRow(at: indexPath!) else { return }
            updateCell(cell, at: indexPath!)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
