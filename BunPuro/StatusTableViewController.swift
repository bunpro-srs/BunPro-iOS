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
    @IBOutlet weak var n4DetailLabel: UILabel!
    @IBOutlet weak var n3DetailLabel: UILabel!
    
    var userResponse: UserResponse?
    var progressResponse: UserProgress?
    var reviewResponse: ReviewResponse?
    
    private let dateComponentsFormatter = DateComponentsFormatter()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
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
        
        self.navigationItem.title = response?.user.name ?? self.navigationItem.title
    }
    
    private func setup(reviews response: ReviewResponse?) {
        
        if let nextReviewDate = response?.nextReviewDate {
            dateComponentsFormatter.unitsStyle = .short
//            dateComponentsFormatter.includesApproximationPhrase = true
            dateComponentsFormatter.includesTimeRemainingPhrase = true
            dateComponentsFormatter.allowedUnits = [.day, .hour, .minute]
            
            self.nextReviewLabel.text = dateComponentsFormatter.string(from: Date(), to: nextReviewDate)
        }
        
        nextHourLabel.text = "\(response?.reviewsWithinNextHour ?? 0)"
        nextDayLabel.text = "\(response?.reviewsTomorrow ?? 0)"
    }
    
    private func setup(progress response: UserProgress?) {
        
        n5DetailLabel.text = response?.n5.localizedProgress ?? "none"
        n4DetailLabel.text = response?.n4.localizedProgress ?? "none"
        n3DetailLabel.text = response?.n3.localizedProgress ?? "none"
    }
    
}
