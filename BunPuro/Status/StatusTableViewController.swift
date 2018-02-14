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
    
    @IBOutlet private weak var statusUpdateActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var nextHourLabel: UILabel! { didSet { nextHourLabel.text = " " } }
    @IBOutlet private weak var nextDayLabel: UILabel! { didSet { nextDayLabel.text = " " } }
    
    @IBOutlet private weak var n5DetailLabel: UILabel! { didSet { n5DetailLabel.text = " " } }
    @IBOutlet private weak var n5ProgressView: UIProgressView!
    
    @IBOutlet private weak var n4DetailLabel: UILabel! { didSet { n4DetailLabel.text = " " } }
    @IBOutlet private weak var n4ProgressView: UIProgressView!
    
    @IBOutlet private weak var n3DetailLabel: UILabel! { didSet { n3DetailLabel.text = " " } }
    @IBOutlet private weak var n3ProgressView: UIProgressView!
    
    @IBOutlet private weak var n2DetailLabel: UILabel! { didSet { n2DetailLabel.text = " " } }
    @IBOutlet private weak var n2ProgressView: UIProgressView!
    
    @IBOutlet private weak var n1DetailLabel: UILabel! { didSet { n1DetailLabel.text = " " } }
    @IBOutlet private weak var n1ProgressView: UIProgressView!
    
    var showReviewsOnViewDidAppear: Bool = false
    
    private let dateComponentsFormatter = DateComponentsFormatter()
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        
        return formatter
    }()
    
    private var logoutObserver: NSObjectProtocol?
    private var beginUpdateObserver: NSObjectProtocol?
    private var endUpdateObserver: NSObjectProtocol?
    
    private var nextReviewDate: Date?
    
    private var userFetchedResultsController: NSFetchedResultsController<Account>?
    private var reviewsFetchedResultsController: NSFetchedResultsController<Review>?
    
    deinit {
        
        print("deinit \(String(describing: self))")
        
        for observer in [logoutObserver, beginUpdateObserver, endUpdateObserver] {
            if observer != nil {
                NotificationCenter.default.removeObserver(observer!)
            }
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
        
        beginUpdateObserver = NotificationCenter.default.addObserver(forName: .BunProWillBeginUpdating, object: nil, queue: nil) { (_) in
            
            DispatchQueue.main.async {
                self.statusUpdateActivityIndicator.startAnimating()
            }
        }
        
        endUpdateObserver = NotificationCenter.default.addObserver(forName: .BunProDidEndUpdating, object: nil, queue: nil) { (_) in
            
            DispatchQueue.main.async {
                self.statusUpdateActivityIndicator.stopAnimating()
            }
        }
        
        setupUserFetchedResultsController()
        setupReviewsFetchedResultsController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if showReviewsOnViewDidAppear {
            
            showReviewsOnViewDidAppear = false
            
            presentReviewViewController()
        }
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
    
    private func setupReviewsFetchedResultsController() {
        
        let request: NSFetchRequest<Review> = Review.fetchRequest()
        
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Review.updatedDate), ascending: true)]
        
        request.predicate = NSPredicate(format: "%K < %@", #keyPath(Review.nextReviewDate), Date().tomorrow.tomorrow.nextMidnight as NSDate)
        
        reviewsFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AppDelegate.coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        reviewsFetchedResultsController?.delegate = self
        
        do {
            try reviewsFetchedResultsController?.performFetch()
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
            
            DispatchQueue.main.async {
                
                AppDelegate.setNeedsStatusUpdate()
            }
        }
        
        Server.add(procedure: reviewProcedure)
    }
    
    private func setup(account: Account?) {
        
        self.navigationItem.title = account?.name ?? NSLocalizedString("Loading...", comment: "")
        
        n5DetailLabel.text = account?.n5?.localizedProgress ?? " "
        n5ProgressView.setProgress(account?.n5?.progress ?? 0, animated: true)
        
        n4DetailLabel.text = account?.n4?.localizedProgress ?? " "
        n4ProgressView.setProgress(account?.n4?.progress ?? 0, animated: true)
        
        n3DetailLabel.text = account?.n3?.localizedProgress ?? " "
        n3ProgressView.setProgress(account?.n3?.progress ?? 0, animated: true)
        
        n2DetailLabel.text = account?.n2?.localizedProgress ?? " "
        n2ProgressView.setProgress(account?.n2?.progress ?? 0, animated: true)
        
        n1DetailLabel.text = account?.n1?.localizedProgress ?? " "
        n1ProgressView.setProgress(account?.n1?.progress ?? 0, animated: true)
    }
    
    private func setup(reviews: [Review]?) {
        
        guard let reviews = reviews else {
            nextReviewTitleLabel?.textColor = UIColor.black
            nextReviewLabel?.text = nil
            nextHourLabel?.text = nil
            nextDayLabel?.text = nil
            lastUpdateLabel.text = nil
            return
        }
        
        if let nextReviewDate = reviews.nextReviewDate {
            
            nextReviewTitleLabel?.textColor = UIColor.black
            
            lastUpdateLabel.text = "Updated: " + dateFormatter.string(from: Date())
            
            if nextReviewDate > Date() {
                
                if self.nextReviewDate != nextReviewDate {
                    
                    UserNotificationCenter.shared.scheduleNextReviewNotification(at: nextReviewDate)
                }
                
                dateComponentsFormatter.unitsStyle = .short
                dateComponentsFormatter.includesTimeRemainingPhrase = true
                dateComponentsFormatter.allowedUnits = [.day, .hour, .minute]
                
                nextReviewLabel?.text = dateComponentsFormatter.string(from: Date(), to: nextReviewDate)
            } else {
                nextReviewTitleLabel?.textColor = UIColor(named: "Main Tint")
                nextReviewLabel?.text = NSLocalizedString("reviewtime.now", comment: "The string that indicates that a review is available")
            }
            
            self.nextReviewDate = nextReviewDate
        }
        
        nextHourLabel?.text = "\(reviews.reviewsWithinNextHour)"
        nextDayLabel?.text = "\(reviews.reviewsTomorrow)"
        
        AppDelegate.updateAppBadgeIcon()
    }
}

extension StatusTableViewController: SegueHandler {
    
    enum SegueIdentifier: String {
        case showN5Grammar
        case showN4Grammar
        case showN3Grammar
        case showN2Grammar
        case showN1Grammar
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
        case .showN2Grammar:
            let destination = segue.destination.content as? GrammarLevelTableViewController
            destination?.level = 2
            destination?.title = "N2"
        case .showN1Grammar:
            let destination = segue.destination.content as? GrammarLevelTableViewController
            destination?.level = 1
            destination?.title = "N1"
        }
    }
}

extension StatusTableViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if controller == userFetchedResultsController, let account = userFetchedResultsController?.fetchedObjects?.first {
            
            setup(account: account)
        } else if controller == reviewsFetchedResultsController {
            
            setup(reviews: reviewsFetchedResultsController?.fetchedObjects)
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
    
    var n2: Level? {
        return (levels?.allObjects as? [Level])?.first(where: { $0.name == "N2" })
    }
    
    var n1: Level? {
        return (levels?.allObjects as? [Level])?.first(where: { $0.name == "N1" })
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

extension Collection where Iterator.Element == Review {
    
    public var nextReviewDate: Date? {
        
        let allDates = filter { $0.complete }.flatMap { $0.nextReviewDate }
        
        let tmp = allDates.reduce(Date.distantFuture, { $0 < $1 ? $0 : $1 })
        return tmp == Date.distantPast ? nil: tmp
    }
    
    public var reviewsWithinNextHour: Int {
        
        let date = Date()
        let result = filter({ $0.complete && $0.nextReviewDate!.hours(from: date) <= 0 })
        return result.count
    }
    
    public var reviewsTomorrow: Int {
        
        return filter({ $0.complete && $0.nextReviewDate!.isTomorrow() }).count
    }
}

extension Date {
    
    func hours(from date: Date) -> Int {
        
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour!
    }
    
    func isTomorrow() -> Bool {
        
        return Calendar.current.isDateInTomorrow(self)
    }
    
    var yesterday: Date {
        
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    
    var tomorrow: Date {
        
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    
    var noon: Date {
        
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    
    var nextMidnight: Date {
        
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
    
    var month: Int {
        
        return Calendar.current.component(.month,  from: self)
    }
    
    var isLastDayOfMonth: Bool {
        
        return tomorrow.month != month
    }
}
