//
//  StatusTableViewController.swift
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
    
    var showReviewsOnViewDidAppear: Bool = false
    
    private var logoutObserver: NSObjectProtocol?
    private var beginUpdateObserver: NSObjectProtocol?
    private var endUpdateObserver: NSObjectProtocol?
    
    private var nextReviewDate: Date?
    private var reviews: [Review]?
    
    private var userFetchedResultsController: NSFetchedResultsController<Account>?
    private var reviewsFetchedResultsController: NSFetchedResultsController<Review>?
    private var jlptFetchedResultsController: NSFetchedResultsController<JLPT>?
    
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
        
        let backgroundImageView = UIImageView(image: #imageLiteral(resourceName: "background"))
        backgroundImageView.contentMode = .scaleAspectFill
        
        tableView.backgroundView = backgroundImageView
        tableView.backgroundView?.addMotion()
        
        logoutObserver = NotificationCenter.default.addObserver(forName: .ServerDidLogoutNotification, object: nil, queue: nil) { [weak self] (_) in
            
            DispatchQueue.main.async {
                self?.setup(account: nil)
                self?.setup(reviews: nil)
            }
        }
        
        beginUpdateObserver = NotificationCenter.default.addObserver(forName: .BunProWillBeginUpdating, object: nil, queue: nil) { (_) in
            
            DispatchQueue.main.async {
                self.statusCell()?.isUpdating = AppDelegate.isUpdating
            }
        }
        
        endUpdateObserver = NotificationCenter.default.addObserver(forName: .BunProDidEndUpdating, object: nil, queue: nil) { (_) in
            
            DispatchQueue.main.async {
                self.statusCell()?.isUpdating = AppDelegate.isUpdating
                self.refreshControl?.endRefreshing()
            }
        }
        
        
        setupUserFetchedResultsController()
        setupReviewsFetchedResultsController()
        setupJLPTFetchedResultsController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if showReviewsOnViewDidAppear {
            
            showReviewsOnViewDidAppear = false
            
            presentReviewViewController()
        }
    }
    
    private func statusCell() -> StatusTableViewCell? {
        
        let indexPath = IndexPath(row: 0, section: 0)
        
        return tableView.cellForRow(at: indexPath) as? StatusTableViewCell
    }
    
    @IBAction func refresh(_ sender: UIRefreshControl) {
        
        AppDelegate.setNeedsStatusUpdate()
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
    
    private func setupJLPTFetchedResultsController() {
        
        let request: NSFetchRequest<JLPT> = JLPT.fetchRequest()
        
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(JLPT.name), ascending: false)]
        
        jlptFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AppDelegate.coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        jlptFetchedResultsController?.delegate = self
        
        do {
            try jlptFetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return section == 0 ? 1 : jlptFetchedResultsController?.fetchedObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(for: indexPath) as StatusTableViewCell
            
            updateStatusCell(cell)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(for: indexPath) as JLPTProgressTableViewCell
            
            let correctedIndexPath = IndexPath(row: indexPath.row, section: 0)
            
            let jlpt = jlptFetchedResultsController!.object(at: correctedIndexPath)
            updateJLPTCell(cell, jlpt: jlpt)
            
            return cell
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
    }
    
    private var lastUpdateDate: Date?
    
    private var nextReviewsCount: Int = 0
    
    private func setup(reviews: [Review]?) {
        
        if let reviewDate = reviews?.nextReviewDate, self.nextReviewDate != reviewDate {
            UserNotificationCenter.shared.scheduleNextReviewNotification(at: reviewDate)
        }
        
        nextReviewDate = reviews?.nextReviewDate
        self.reviews = reviews
        if let nextReviewDate = nextReviewDate {
            nextReviewsCount = reviews?.reviews(at: nextReviewDate).count ?? 0
        }
        lastUpdateDate = Date()
        
        if let cell = statusCell() {
            updateStatusCell(cell)
        }

        AppDelegate.updateAppBadgeIcon()
    }
    
    private func updateStatusCell(_ cell: StatusTableViewCell) {
        cell.nextReviewDate = nextReviewDate
        
        if let date = nextReviewDate {
            
            if date < Date() {
                cell.nextReviewsCount = AppDelegate.badgeNumber()?.intValue ?? 0
            } else {
                cell.nextReviewsCount = AppDelegate.badgeNumber(date: date)?.intValue ?? 0
            }
        } else {
            cell.nextReviewsCount = 0
        }
        
        cell.nextHourReviewCount = reviews?.reviewsWithinNextHour
        cell.nextDayReviewCount = reviews?.reviewsWithNext24Hours
        cell.lastUpdateDate = lastUpdateDate
    }
    
    private func updateJLPTCell(_ cell: JLPTProgressTableViewCell, jlpt: JLPT) {
        
        cell.titleLabel.text = jlpt.name
        cell.subtitleLabel.text = jlpt.localizedProgressString
        cell.setProgress(jlpt.progress, animated: true)
    }
}

extension StatusTableViewController: SegueHandler {
    
    enum SegueIdentifier: String {
        case showJLPT
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) else { return }
        
        switch segueIdentifier(for: segue) {
        case .showJLPT:
            
            let correctedIndexPath = IndexPath(row: indexPath.row, section: 0)
            let jlpt = jlptFetchedResultsController?.object(at: correctedIndexPath)
            
            let destination = segue.destination.content as? GrammarLevelTableViewController
            destination?.level = Int(jlpt?.level ?? 0)
            destination?.title = jlpt?.name
        }
    }
}

extension StatusTableViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if controller == userFetchedResultsController, let account = userFetchedResultsController?.fetchedObjects?.first {
            
            setup(account: account)
        } else if controller == reviewsFetchedResultsController {
            
            setup(reviews: reviewsFetchedResultsController?.fetchedObjects)
        } else if controller == jlptFetchedResultsController {
            
            let updatedIndexPath = IndexPath(row: indexPath!.row, section: 1)
            
            if let cell = tableView.cellForRow(at: updatedIndexPath) as? JLPTProgressTableViewCell, let jlpt = anObject as? JLPT {
            
                updateJLPTCell(cell, jlpt: jlpt)
            }
        }
    }
}

extension StatusTableViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true, completion: nil)
    }
}

private extension Lesson {
    
    var finishedGrammarCount: Int {
        return Int(Float(grammar?.count ?? 0) * progress)
    }
}

private extension JLPT {
    
    var finishedLessonsCount: Int {
        return (lessons?.allObjects as? [Lesson])?.reduce(0, { $0 + $1.finishedGrammarCount }) ?? 0
    }
    
    var lessonCount: Int {
        return (lessons?.allObjects as? [Lesson])?.reduce(0, { $0 + ($1.grammar?.count ?? 0) }) ?? 0
    }
    
    var progress: Float {
        guard lessonCount > 0 else { return 0.0 }
        
        return Float(finishedLessonsCount) / Float(lessonCount)
    }
    
    var localizedProgressString: String {
        return "\(finishedLessonsCount) / \(lessonCount)"
    }
}

extension Collection where Iterator.Element == Review {
    
    public var nextReviewDate: Date? {
        
        let allDates = filter { $0.complete }.compactMap { $0.nextReviewDate }
        
        let tmp = allDates.reduce(Date.distantFuture, { $0 < $1 ? $0 : $1 })
        return tmp == Date.distantPast ? nil: tmp
    }
    
    public func reviews(at date: Date) -> [Review] {
        
        let result = filter({ $0.complete && $0.nextReviewDate!.minutes(from: date) <= 0 })
        return result
    }
    
    public var reviewsWithinNextHour: Int {
        
        let date = Date()
        let result = filter({ $0.complete && $0.nextReviewDate!.hours(from: date) <= 0 })
        return result.count
    }
    
    public var reviewsWithNext24Hours: Int {
        
        let date = Date()
        let result = filter({ $0.complete && $0.nextReviewDate!.hours(from: date) <= 23 })
        return result.count
    }
    
    public var reviewsTomorrow: Int {
        
        return filter({ $0.complete && $0.nextReviewDate!.isTomorrow() }).count
    }
}

extension Date {
    
    func minutes(from date: Date) -> Int {
        
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute!
    }
    
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
