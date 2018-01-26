//
//  GrammarTableViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 21.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import CoreData
import SafariServices
import BunPuroKit

protocol GrammarPresenter {
    var grammar: Grammar? { get set }
}

class GrammarViewController: UITableViewController, GrammarPresenter {

    enum ViewMode: Int {
        case examples
        case reading
    }
    
    @IBOutlet private var selectionSectionHeaderView: UIView!
    @IBOutlet private weak var viewModeSegmentedControl: UISegmentedControl!
    private var exampleSentencesFetchedResultsController: NSFetchedResultsController<Sentence>!
    private var readingsFetchedResultsController: NSFetchedResultsController<Link>!
    
    var grammar: Grammar?
    private var review: Review? {
        return grammar?.review
    }
    
    private var viewMode: ViewMode = .examples {
        didSet {
            viewModeSegmentedControl?.selectedSegmentIndex = viewMode.rawValue
            
            tableView.reloadSections(IndexSet([1]), with: .none)
        }
    }
    
    private var endUpdateObserver: NSObjectProtocol?
    
    deinit {
        
        print("deinit \(String(describing: self))")
        
        for observer in [endUpdateObserver] {
            if observer != nil {
                NotificationCenter.default.removeObserver(observer!)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(grammar != nil)
        
        endUpdateObserver = NotificationCenter.default.addObserver(
            forName: .BunProDidEndUpdating,
            object: nil,
            queue: nil) { [weak self] (_) in
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) { [weak self] in
                    
                    print("Reload because reviews did change")
                    self?.tableView.beginUpdates()
                    self?.tableView.reloadSections(IndexSet([0]), with: .none)
                    self?.tableView.endUpdates()
                }
        }
        
        setupSentencesFetchedResultsController()
        setupReadingsFetchedResultsController()
    }

    @IBAction private func viewModeChanged(_ sender: UISegmentedControl) {
        guard let newViewMode = ViewMode(rawValue: sender.selectedSegmentIndex) else {
            fatalError("ViewMode (\(sender.selectedSegmentIndex)) not supported.")
        }
        
        viewMode = newViewMode
    }
    
    @IBAction private func edidReviewButtonPressed(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if review?.complete == true {
            
            let removeAction = UIAlertAction(
                title: NSLocalizedString("review.edit.remove", comment: ""),
                style: .destructive) { (_) in
                    self.modifyReview(.remove(self.review!.identifier))
            }
            
            alertController.addAction(removeAction)
            
            let resetAction = UIAlertAction(
                title: NSLocalizedString("review.edit.reset", comment: ""),
                style: .destructive) { (_) in
                    self.modifyReview(.reset(self.review!.identifier))
            }
            
            alertController.addAction(resetAction)
        } else {
            
            let addAction = UIAlertAction(
                title: NSLocalizedString("review.edit.add", comment: ""),
                style: .default) { (_) in
                    
                    self.modifyReview(.add(self.grammar!.identifier))
            }
            
            alertController.addAction(addAction)
        }
        
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("general.cancel", comment: ""), style: .cancel, handler: nil)
        )
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        present(alertController, animated: true)
    }
    
    private func modifyReview(_ modificationType: ModifyReviewProcedure.ModificationType) {
        
        let addProcedure = ModifyReviewProcedure(presentingViewController: self, modificationType: modificationType) { (error) in
            print(error ?? "No Error")
            
            if error == nil {
                
                DispatchQueue.main.async {
                    
                    AppDelegate.setNeedsStatusUpdate()
                }
            }
        }
        
        Server.add(procedure: addProcedure)
    }
    
    private func setupSentencesFetchedResultsController() {
        
        let request: NSFetchRequest<Sentence> = Sentence.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(Sentence.grammar), grammar!)
        
        let sort = NSSortDescriptor(key: #keyPath(Sentence.identifier), ascending: true)
        request.sortDescriptors = [sort]
        
        exampleSentencesFetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
            sectionNameKeyPath: nil, cacheName: nil
        )
        
        exampleSentencesFetchedResultsController?.delegate = self
        
        do {
            try exampleSentencesFetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
    }
    
    private func setupReadingsFetchedResultsController() {
        
        let request: NSFetchRequest<Link> = Link.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(Link.grammar), grammar!)
        
        let sort = NSSortDescriptor(key: #keyPath(Link.id), ascending: true)
        request.sortDescriptors = [sort]
        
        readingsFetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
            sectionNameKeyPath: nil, cacheName: nil
        )
        
        readingsFetchedResultsController?.delegate = self
        
        do {
            try readingsFetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return review?.complete == true ? 3 : 2
        default:
            switch viewMode {
            case .examples:
                return exampleSentencesFetchedResultsController?.fetchedObjects?.count ?? 0
            case .reading:
                return readingsFetchedResultsController?.fetchedObjects?.count ?? 0
            }
        }
    }
    
    private enum Info: Int {
        
        case basic
        case structure
        case streak
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            
            switch Info(rawValue: indexPath.row)! {
            case .basic:
                
                let cell = tableView.dequeueReusableCell(for: indexPath) as BasicInfoCell
                
                cell.titleLabel.text = grammar?.title
                cell.meaningLabel.text = grammar?.meaning
                
                if let caution = grammar?.caution, !caution.isEmpty {
                    cell.cautionLabel.text = "⚠️ \(caution)"
                } else {
                    cell.cautionLabel.text = nil
                    cell.cautionLabel.isHidden = true
                }
                
                cell.separatorInset = UIEdgeInsets(top: 0, left: 100000, bottom: 0, right: 0)
                
                return cell
            
            case .structure:
                
                let cell = tableView.dequeueReusableCell(for: indexPath) as StructureInfoCell
                
                cell.descriptionLabel.text = grammar?.structure?.replacingOccurrences(of: ", ", with: "\n")
                
                cell.separatorInset = UIEdgeInsets(top: 0, left: 100000, bottom: 0, right: 0)
                
                return cell
                
            case .streak:
                
                let cell = tableView.dequeueReusableCell(for: indexPath) as StreakInfoCell
                cell.streak = Int(review?.streak ?? 0)
                
                return cell
            }
            
        default:
            let cell = tableView.dequeueReusableCell(for: indexPath) as DetailCell
            
            switch viewMode {
            case .examples:
                
                let correctIndexPath = IndexPath(row: indexPath.row, section: 0)
                
                let sentence = exampleSentencesFetchedResultsController.object(at: correctIndexPath)
                
                let japaneseFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 15))
                let englishFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 12))
                
                cell.nameLabel?.attributedText = sentence.japanese?.htmlAttributedString(font: japaneseFont)
                cell.descriptionLabel?.attributedText = sentence.english?.htmlAttributedString(font: englishFont)
                
                cell.selectionStyle = .none

            case .reading:
                
                let correctIndexPath = IndexPath(row: indexPath.row, section: 0)
                
                let link = readingsFetchedResultsController.object(at: correctIndexPath)
                
                let font1 = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 12))
                let font2 = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 10))
                
                cell.nameLabel?.attributedText = link.site?.htmlAttributedString(font: font1)
                cell.descriptionLabel?.attributedText = link.about?.htmlAttributedString(font: font2)
                
                cell.selectionStyle = .default
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1, viewMode == .reading {
            
            defer {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            let correctIndexPath = IndexPath(row: indexPath.row, section: 0)
            guard let url = readingsFetchedResultsController.object(at: correctIndexPath).url else { return }
            
            let safariViewController = SFSafariViewController(url: url)
            
            present(safariViewController, animated: true, completion: nil)
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        return section == 1 ? selectionSectionHeaderView : nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return section == 1 ? 29 + 16 + 16 : 0
    }
}

extension GrammarViewController: NSFetchedResultsControllerDelegate {
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert: tableView.insertSections([sectionIndex], with: .fade)
        case .delete: tableView.deleteSections([sectionIndex], with: .fade)
        default: break
        }
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        let currentPresentingController: NSFetchedResultsController<NSFetchRequestResult>?
        
        switch viewMode {
        case .examples:
            currentPresentingController = exampleSentencesFetchedResultsController as? NSFetchedResultsController<NSFetchRequestResult>
        case .reading:
            currentPresentingController = readingsFetchedResultsController as? NSFetchedResultsController<NSFetchRequestResult>
        }
        
        guard controller == currentPresentingController else { return }
        
        tableView.reloadSections(IndexSet([0]), with: .none)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
