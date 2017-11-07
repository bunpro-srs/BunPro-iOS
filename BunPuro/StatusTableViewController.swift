//
//  FirstViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import BunPuroKit

class StatusTableViewController: UITableViewController {
    
    @IBOutlet weak var nextReviewTitleLabel: UILabel!
    
    @IBOutlet weak var nextReviewLabel: UILabel!
    @IBOutlet weak var nextHourLabel: UILabel!
    @IBOutlet weak var nextDayLabel: UILabel!
    
    @IBOutlet weak var n5DetailLabel: UILabel!
    @IBOutlet weak var n5ProgressView: UIProgressView!
    
    @IBOutlet weak var n4DetailLabel: UILabel!
    @IBOutlet weak var n4ProgressView: UIProgressView!
    
    @IBOutlet weak var n3DetailLabel: UILabel!
    @IBOutlet weak var n3ProgressView: UIProgressView!
    
    private let dateComponentsFormatter = DateComponentsFormatter()
    
    private var timer: Timer? = nil { didSet { timer?.tolerance = 10.0 } }
    private var becomeInactiveObserver: NSObjectProtocol?
    private var becomeActiveObserver: NSObjectProtocol?
    
    deinit {
        if becomeActiveObserver != nil {
            NotificationCenter.default.removeObserver(becomeActiveObserver!)
        }
        
        if becomeInactiveObserver != nil {
            NotificationCenter.default.removeObserver(becomeInactiveObserver!)
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        becomeActiveObserver = NotificationCenter.default.addObserver(forName: .UIApplicationDidBecomeActive, object: nil, queue: nil) { [weak self] (_) in
            self?.setup(reviews: Server.reviewResponse)
        }
        
        becomeInactiveObserver = NotificationCenter.default.addObserver(forName: .UIApplicationWillResignActive, object: nil, queue: nil) { [weak self] (_) in
            self?.timer?.invalidate()
        }
        
        setup(user: Server.userResponse)
        setup(progress: Server.userProgress)
        setup(reviews: Server.reviewResponse)
        
        updateLastUpdatedStatus()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        setup(reviews: Server.reviewResponse)
    }
    
    @IBAction func refresh(_ sender: UIRefreshControl) {
        
        refreshStatus()
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if indexPath.section == 0 && (indexPath.row == 1 || indexPath.row == 2) {
            return nil
        }
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            
            tableView.deselectRow(at: indexPath, animated: true)
            
            let alertController = UIAlertController(title: "Uh oh", message: "Not yet implemented ;_;", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "OK...", style: .cancel, handler: nil)
            
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    private func refreshStatus() {
        
        Server.updatedStatus { (error) in
            guard error == nil else { self.refreshControl?.endRefreshing(); return }
            
            self.setup(user: Server.userResponse)
            self.setup(progress: Server.userProgress)
            self.setup(reviews: Server.reviewResponse)
            
            self.refreshControl?.endRefreshing()
            self.updateLastUpdatedStatus()
        }
    }
    
    private func updateLastUpdatedStatus() {
        refreshControl?.attributedTitle = NSAttributedString(string: String.localizedStringWithFormat(NSLocalizedString("status.lastupdate", comment: "The last time an update was made."), DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)))
    }
    
    private func setup(user response: UserResponse?) {
        
        guard let response = response else { return }
        
        self.navigationItem.title = response.user.name
    }
    
    private func setup(reviews response: ReviewResponse?) {
        
        guard let response = response else { return }
        
        if let nextReviewDate = response.nextReviewDate {
            
            self.nextReviewTitleLabel.textColor = UIColor.black
            
            if nextReviewDate > Date() {
                
                UserNotificationCenter.shared.scheduleNextReviewNotification(at: nextReviewDate)
                
                dateComponentsFormatter.unitsStyle = .short
                dateComponentsFormatter.includesTimeRemainingPhrase = true
                dateComponentsFormatter.allowedUnits = [.day, .hour, .minute]
                
                self.nextReviewLabel.text = dateComponentsFormatter.string(from: Date(), to: nextReviewDate)
                
                timer?.invalidate()
                
                timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { [weak self] (_) in
                    self?.setup(reviews: Server.reviewResponse)
                })
            } else {
                self.nextReviewTitleLabel.textColor = UIColor(named: "Main Tint")
                self.nextReviewLabel.text = NSLocalizedString("reviewtime.now", comment: "The string that indicates that a review is available")
            }
        }
        
        nextHourLabel.text = "\(response.reviewsWithinNextHour)"
        nextDayLabel.text = "\(response.reviewsTomorrow)"
    }
    
    private func setup(progress response: UserProgress?) {
        
        guard let response = response else { return }
        
        n5DetailLabel.text = response.n5.localizedProgress ?? n5DetailLabel.text
        n5ProgressView.progress = response.n5.progress
        
        n4DetailLabel.text = response.n4.localizedProgress ?? n4DetailLabel.text
        n4ProgressView.progress = response.n4.progress
        
        n3DetailLabel.text = response.n3.localizedProgress ?? n3DetailLabel.text
        n3ProgressView.progress = response.n3.progress
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
