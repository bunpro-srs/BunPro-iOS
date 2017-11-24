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

class StatusTableViewController: UITableViewController {
    
    @IBOutlet weak var nextReviewTitleLabel: UILabel!
    
    @IBOutlet weak var nextReviewLabel: UILabel! { didSet { nextReviewLabel.text = " " } }
    @IBOutlet weak var nextHourLabel: UILabel! { didSet { nextHourLabel.text = " " } }
    @IBOutlet weak var nextDayLabel: UILabel! { didSet { nextDayLabel.text = " " } }
    
    @IBOutlet weak var n5DetailLabel: UILabel! { didSet { n5DetailLabel.text = " " } }
    @IBOutlet weak var n5ProgressView: UIProgressView!
    
    @IBOutlet weak var n4DetailLabel: UILabel! { didSet { n4DetailLabel.text = " " } }
    @IBOutlet weak var n4ProgressView: UIProgressView!
    
    @IBOutlet weak var n3DetailLabel: UILabel! { didSet { n3DetailLabel.text = " " } }
    @IBOutlet weak var n3ProgressView: UIProgressView!
    
    private let dateComponentsFormatter = DateComponentsFormatter()
    
    private var becomeInactiveObserver: NSObjectProtocol?
    private var becomeActiveObserver: NSObjectProtocol?
    
    private var repeatProcedure: RepeatProcedure<StatusProcedure>?
    
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
            self?.refreshStatus()
        }
        
        becomeInactiveObserver = NotificationCenter.default.addObserver(forName: .UIApplicationWillResignActive, object: nil, queue: nil) { [weak self] (_) in
            self?.repeatProcedure?.cancel()
        }
        
        refreshStatus()
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
        
        repeatProcedure = RepeatProcedure(dispatchQueue: nil, max: nil, wait: WaitStrategy.constant(60)) {
            StatusProcedure(presentingViewController: self) { (user, progress, reviews, error) in
                
                DispatchQueue.main.async {
                    self.setup(user: user)
                    self.setup(progress: progress)
                    self.setup(reviews: reviews)
                }
            }
        }
                
        Server.add(procedure: repeatProcedure!)
    }
    
    private func setup(user: User?) {
        
        guard let user = user else { return }
        
        self.navigationItem.title = user.name
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
        n5ProgressView.setProgress(response.n5.progress, animated: true)
        
        n4DetailLabel.text = response.n4.localizedProgress ?? n4DetailLabel.text
        n4ProgressView.setProgress(response.n4.progress, animated: true)
        
        n3DetailLabel.text = response.n3.localizedProgress ?? n3DetailLabel.text
        n3ProgressView.setProgress(response.n3.progress, animated: true)
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
