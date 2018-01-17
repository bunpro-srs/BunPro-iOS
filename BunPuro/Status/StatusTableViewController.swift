//
//  FirstViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import BunPuroKit
import ProcedureKit
import SafariServices
import CoreData

private let updateInterval = TimeInterval(60)

class StatusTableViewController: UITableViewController {
    
    @IBOutlet private weak var lastUpdateLabel: UILabel!  { didSet { lastUpdateLabel.text = " " } }
    
    @IBOutlet private weak var nextReviewTitleLabel: UILabel!
    
    @IBOutlet private weak var nextReviewLabel: UILabel! { didSet { nextReviewLabel.text = " " } }
    @IBOutlet private weak var nextHourLabel: UILabel! { didSet { nextHourLabel.text = " " } }
    @IBOutlet private weak var nextDayLabel: UILabel! { didSet { nextDayLabel.text = " " } }
    
    @IBOutlet private weak var n5DetailLabel: UILabel! { didSet { n5DetailLabel.text = " " } }
    @IBOutlet private weak var n5ProgressView: UIProgressView!
    
    @IBOutlet private weak var n4DetailLabel: UILabel! { didSet { n4DetailLabel.text = " " } }
    @IBOutlet private weak var n4ProgressView: UIProgressView!
    
    @IBOutlet private weak var n3DetailLabel: UILabel! { didSet { n3DetailLabel.text = " " } }
    @IBOutlet private weak var n3ProgressView: UIProgressView!
    
    private let dateComponentsFormatter = DateComponentsFormatter()
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        
        return formatter
    }()
    
    private var logoutObserver: NSObjectProtocol?
    
    private var nextReviewDate: Date?
    
    private var userFetchedResultsController: NSFetchedResultsController<Account>?
    
    deinit {
        if logoutObserver != nil {
            NotificationCenter.default.removeObserver(logoutObserver!)
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        logoutObserver = NotificationCenter.default.addObserver(forName: .ServerDidLogoutNotification, object: nil, queue: nil) { [weak self] (_) in
            
            DispatchQueue.main.async {
                self?.setup(account: nil)
                self?.setup(reviews: nil)
            }
        }
        
        setupUserFetchedResultsController()
    }
    
    private func setupUserFetchedResultsController() {
        
        let request: NSFetchRequest<Account> = Account.fetchRequest()
        
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Account.name), ascending: true)]
        
        userFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AppDelegate.coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        userFetchedResultsController?.delegate = self
        
        do {
            try userFetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                if let nextReviewDate = nextReviewDate {
                    return nextReviewDate < Date() ? indexPath : nil
                }
                return nil
            default: return nil
            }
            
        default:
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            
            tableView.deselectRow(at: indexPath, animated: true)
            
            presentReviewViewController()
        }
    }
    
    func presentReviewViewController() {
        
        let reviewProcedure = ReviewViewControllerProcedure(presentingViewController: tabBarController!)
        
        reviewProcedure.completionBlock = {
            // Throw Notification
        }
        
        Server.add(procedure: reviewProcedure)
    }
    
    private func setup(account: Account?) {
        
        self.navigationItem.title = account?.name ?? NSLocalizedString("Loading...", comment: "")
        
        n5DetailLabel.text = account?.n5?.localizedProgress
        n5ProgressView.setProgress(account?.n5?.progress ?? 0, animated: true)
        
        n4DetailLabel.text = account?.n4?.localizedProgress
        n4ProgressView.setProgress(account?.n4?.progress ?? 0, animated: true)
        
        n3DetailLabel.text = account?.n3?.localizedProgress
        n3ProgressView.setProgress(account?.n3?.progress ?? 0, animated: true)
    }
    
    private func setup(reviews response: ReviewResponse?) {
        
        guard let response = response else {
            nextReviewTitleLabel?.textColor = UIColor.black
            nextReviewLabel?.text = nil
            nextHourLabel?.text = nil
            nextDayLabel?.text = nil
            lastUpdateLabel.text = nil
            return
        }
        
        if let nextReviewDate = response.nextReviewDate {
            
            self.nextReviewDate = nextReviewDate
            nextReviewTitleLabel?.textColor = UIColor.black
            
            lastUpdateLabel.text = "Updated: " + dateFormatter.string(from: Date())
            
            if nextReviewDate > Date() {
                
                UserNotificationCenter.shared.scheduleNextReviewNotification(at: nextReviewDate)
                
                dateComponentsFormatter.unitsStyle = .short
                dateComponentsFormatter.includesTimeRemainingPhrase = true
                dateComponentsFormatter.allowedUnits = [.day, .hour, .minute]
                
                nextReviewLabel?.text = dateComponentsFormatter.string(from: Date(), to: nextReviewDate)
            } else {
                nextReviewTitleLabel?.textColor = UIColor(named: "Main Tint")
                nextReviewLabel?.text = NSLocalizedString("reviewtime.now", comment: "The string that indicates that a review is available")
            }
        }
        
        nextHourLabel?.text = "\(response.reviewsWithinNextHour)"
        nextDayLabel?.text = "\(response.reviewsTomorrow)"
    }
}

extension StatusTableViewController: SegueHandler {
    
    enum SegueIdentifier: String {
        case showN5Grammar
        case showN4Grammar
        case showN3Grammar
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segueIdentifier(for: segue) {
        case .showN5Grammar:
            let destination = segue.destination.content as? GrammarLevelTableViewController
            destination?.level = 5
            destination?.title = "N5"
        case .showN4Grammar:
            let destination = segue.destination.content as? GrammarLevelTableViewController
            destination?.level = 4
            destination?.title = "N4"
        case .showN3Grammar:
            let destination = segue.destination.content as? GrammarLevelTableViewController
            destination?.level = 3
            destination?.title = "N3"
        }
    }
}

extension StatusTableViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if controller == userFetchedResultsController, let account = userFetchedResultsController?.fetchedObjects?.first {
            
            setup(account: account)
        }
    }
}

extension StatusTableViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true, completion: nil)
    }
}

private extension Account {
    
    var n5: Level? {
        return (levels?.allObjects as? [Level])?.first(where: { $0.name == "N5" })
    }
    
    var n4: Level? {
        return (levels?.allObjects as? [Level])?.first(where: { $0.name == "N4" })
    }
    
    var n3: Level? {
        return (levels?.allObjects as? [Level])?.first(where: { $0.name == "N3" })
    }
}

private extension Level {
    
    var progress: Float {
        guard max > 0 else { return 0.0 }
        
        return Float(current) / Float(max)
    }
    
    var localizedProgress: String? {
        
        return "\(current) / \(max)"
    }
}
