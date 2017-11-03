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
    
    @IBOutlet weak var nextReviewLabel: UILabel!
    @IBOutlet weak var nextHourLabel: UILabel!
    @IBOutlet weak var nextDayLabel: UILabel!
    
    @IBOutlet weak var n5DetailLabel: UILabel!
    @IBOutlet weak var n5ProgressView: UIProgressView!
    
    @IBOutlet weak var n4DetailLabel: UILabel!
    @IBOutlet weak var n4ProgressView: UIProgressView!
    
    @IBOutlet weak var n3DetailLabel: UILabel!
    @IBOutlet weak var n3ProgressView: UIProgressView!
    
    var userResponse: UserResponse?
    var progressResponse: UserProgress?
    var reviewResponse: ReviewResponse?
    
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
            self?.setup(reviews: self?.reviewResponse)
        }
        
        becomeInactiveObserver = NotificationCenter.default.addObserver(forName: .UIApplicationWillResignActive, object: nil, queue: nil) { [weak self] (_) in
            self?.timer?.invalidate()
        }
        
        setup(user: userResponse)
        setup(progress: progressResponse)
        setup(reviews: reviewResponse)
    }
    
    @IBAction func refresh(_ sender: UIRefreshControl) {
        
        refreshStatus()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 && indexPath.row == 0 {
            
            let alertController = UIAlertController(title: "Uh oh", message: "Not yet implemented ;_;", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "OK...", style: .cancel, handler: nil)
            
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    private func refreshStatus() {
                
        Server.updatedStatus { (userResponse, userProgress, reviewResponse, error) in
            
            DispatchQueue.main.async {
                
                self.setup(user: userResponse)
                self.setup(reviews: reviewResponse)
                self.setup(progress: userProgress)
                
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    private func setup(user response: UserResponse?) {
        
        guard let response = response else { return }
        
        self.navigationItem.title = response.user.name
    }
    
    private func setup(reviews response: ReviewResponse?) {
        
        guard let response = response else { return }
        
        if let nextReviewDate = response.nextReviewDate {
            
            if nextReviewDate > Date() {
                
                UserNotificationCenter.shared.scheduleNextReviewNotification(at: nextReviewDate)
                
                dateComponentsFormatter.unitsStyle = .short
                dateComponentsFormatter.includesTimeRemainingPhrase = true
                dateComponentsFormatter.allowedUnits = [.day, .hour, .minute]
                
                self.nextReviewLabel.text = dateComponentsFormatter.string(from: Date(), to: nextReviewDate)
                
                timer?.invalidate()
                
                timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { [weak self] (_) in
                    self?.setup(reviews: self?.reviewResponse)
                })
            } else {
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
