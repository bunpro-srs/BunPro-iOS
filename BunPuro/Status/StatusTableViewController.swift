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
    
    private var becomeInactiveObserver: NSObjectProtocol?
    private var becomeActiveObserver: NSObjectProtocol?
    private var logoutObserver: NSObjectProtocol?
    
    private var statusUpdateProcedure: StatusProcedure?
    private weak var statusUpdateTimer: Timer?
    
    private var didReloadOnFirstAppearance: Bool = false
    private var nextReviewDate: Date?
    
    deinit {
        if becomeActiveObserver != nil {
            NotificationCenter.default.removeObserver(becomeActiveObserver!)
        }
        
        if becomeInactiveObserver != nil {
            NotificationCenter.default.removeObserver(becomeInactiveObserver!)
        }
        
        if logoutObserver != nil {
            NotificationCenter.default.removeObserver(logoutObserver!)
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        becomeActiveObserver = NotificationCenter.default.addObserver(forName: .UIApplicationDidBecomeActive, object: nil, queue: nil) { [weak self] (_) in
            self?.scheduleUpdateProcedure()
            self?.refreshStatus()
        }
        
        becomeInactiveObserver = NotificationCenter.default.addObserver(forName: .UIApplicationWillResignActive, object: nil, queue: nil) { [weak self] (_) in
            
            self?.statusUpdateProcedure?.cancel()
            self?.statusUpdateProcedure = nil
            
            self?.statusUpdateTimer?.invalidate()
        }
        
        logoutObserver = NotificationCenter.default.addObserver(forName: .ServerDidLogoutNotification, object: nil, queue: nil) { [weak self] (_) in
            
            self?.statusUpdateProcedure?.cancel()
            self?.statusUpdateProcedure = nil
            self?.statusUpdateTimer?.invalidate()
            
            self?.scheduleUpdateProcedure()
            self?.refreshStatus()
            
            DispatchQueue.main.async {
                self?.setup(user: nil)
                self?.setup(progress: nil)
                self?.setup(reviews: nil)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didReloadOnFirstAppearance {
            scheduleUpdateProcedure()
            refreshStatus()
            
            didReloadOnFirstAppearance = true
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
            self.scheduleUpdateProcedure()
        }
        
        Server.add(procedure: reviewProcedure)
    }
    
    private func refreshStatus() {
        
        statusUpdateTimer?.invalidate()
        
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { (_) in
            self.scheduleUpdateProcedure()
        }
    }
    
    private func scheduleUpdateProcedure() {
        
        statusUpdateProcedure = StatusProcedure(presentingViewController: self) { (user, progress, reviews, error) in
            
            DispatchQueue.main.async {
                self.setup(user: user)
                self.setup(progress: progress)
                self.setup(reviews: reviews)
                
                self.statusUpdateProcedure = nil
            }
            
            if let error = error as? Swift.DecodingError {
                switch error {
                case .keyNotFound(_, _):
                    self.scheduleUpdateProcedure()
                default:
                    print(error)
                }
            }
        }
        
        if !didReloadOnFirstAppearance {
            
            let request: NSFetchRequest<Grammar> = Grammar.fetchRequest()
            
            let context = AppDelegate.coreDataStack.managedObjectContext
            
            do {
                if try context.fetch(request).isEmpty {
                    let updateGrammarProcedure = UpdateGrammarProcedure(presentingViewController: self, initialImport: true)
                                        
                    Server.add(procedure: updateGrammarProcedure)
                }
            } catch {
                print("Could not load grammar points")
            }
        }
        
        Server.add(procedure: statusUpdateProcedure!)
    }
    
    private func setup(user: User?) {
        
        guard let user = user else {
            self.navigationItem.title = NSLocalizedString("Loading...", comment: "")
            return
        }
        
        self.navigationItem.title = user.name
        
        let importProcedure = ImportAccountIntoCoreDataProcedure(user: user)
        
        Server.add(procedure: importProcedure)
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
    
    private func setup(progress response: UserProgress?) {
        
        n5DetailLabel.text = response?.n5.localizedProgress
        n5ProgressView.setProgress(response?.n5.progress ?? 0, animated: true)
        
        n4DetailLabel.text = response?.n4.localizedProgress
        n4ProgressView.setProgress(response?.n4.progress ?? 0, animated: true)
        
        n3DetailLabel.text = response?.n3.localizedProgress
        n3ProgressView.setProgress(response?.n3.progress ?? 0, animated: true)
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

extension StatusTableViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true, completion: nil)
    }
}
