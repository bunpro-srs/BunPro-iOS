//
//  DataManager.swift
//  BunPuro
//
//  Created by Andreas Braun on 17.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import BunPuroKit
import ProcedureKit
import SafariServices

final class DataManager {
    
    private let procedureQueue = ProcedureQueue()
    
    let presentingViewController: UIViewController
    private let persistentContainer: NSPersistentContainer
    
    private var loginObserver: NSObjectProtocol?
    private var logoutObserver: NSObjectProtocol?
    
    deinit {
        
        if loginObserver != nil {
            NotificationCenter.default.removeObserver(loginObserver!)
        }
        
        if logoutObserver != nil {
            NotificationCenter.default.removeObserver(logoutObserver!)
        }
    }
    
    init(presentingViewController: UIViewController, persistentContainer: NSPersistentContainer = AppDelegate.coreDataStack.storeContainer) {
        self.presentingViewController = presentingViewController
        self.persistentContainer = persistentContainer
        
        loginObserver = NotificationCenter.default.addObserver(forName: .ServerDidLoginNotification, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            
            self?.updateGrammarDatabase()
        }
        
        logoutObserver = NotificationCenter.default.addObserver(forName: .ServerDidLogoutNotification, object: nil, queue: nil) { [weak self] (_) in
            
            DispatchQueue.main.async {
                self?.procedureQueue.add(operation: ResetReviewsProcedure())
                
                self?.scheduleUpdateProcedure()
            }
        }
    }
    
    // Status Updates
    private let updateTimeInterval: TimeInterval = TimeInterval(60 * 5)
    private var startImmediately: Bool = true
    var isUpdating: Bool = false {
        
        didSet {
            DispatchQueue.main.async {
                
                NotificationCenter.default.post(name: self.isUpdating ? .BunProWillBeginUpdating : .BunProDidEndUpdating, object: self)
            }
        }
    }
    private var statusUpdateTimer: Timer? { didSet { statusUpdateTimer?.tolerance = 10.0 } }
    
    private var hasPendingReviewModification: Bool = false
    
    func startStatusUpdates() {
        
        if startImmediately {
            startImmediately = false
            scheduleUpdateProcedure()
        }
        
        guard !isUpdating else { return }
        
        stopStatusUpdates()
        
        statusUpdateTimer = Timer(timeInterval: updateTimeInterval, repeats: true) { (_) in
            
            guard !self.isUpdating else { return }
            self.scheduleUpdateProcedure()
        }
        
        RunLoop.main.add(statusUpdateTimer!, forMode: RunLoop.Mode.default)
    }
    
    func stopStatusUpdates() {
        
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
    }
    
    func immidiateStatusUpdate() {
        
        self.scheduleUpdateProcedure()
    }
    
    private func updateGrammarDatabase() {
        
        let updateProcedure = UpdateGrammarProcedure(presentingViewController: presentingViewController)
        
        Server.add(procedure: updateProcedure)
    }
    
    func signupForTrial() {
        
        self.isUpdating = true
        
        let signupForTrialProcedure = ActivateTrialPeriodProcedure(presentingViewController: presentingViewController) { (user, error) in
            
            guard let user = user else {
                
                DispatchQueue.main.async {
                    self.isUpdating = false
                }
                
                return
            }
            
            DispatchQueue.main.async {
                let importProcedure = ImportAccountIntoCoreDataProcedure(account: user, progress: nil)
                
                importProcedure.addDidFinishBlockObserver { (_, _) in
                    self.isUpdating = false
                }
                
                self.procedureQueue.add(operation: importProcedure)
            }
        }
        
        Server.add(procedure: signupForTrialProcedure)
    }
    
    func signup() {
        let url = URL(string: "https://bunpro.jp")!
        let safariViewController = SFSafariViewController(url: url)
        
        safariViewController.preferredBarTintColor = .black
        safariViewController.preferredControlTintColor = UIColor(named: "Main Tint")
        
        presentingViewController.present(safariViewController, animated: true, completion: nil)
    }
    
    func modifyReview(_ modificationType: ModifyReviewProcedure.ModificationType) {
        
        let addProcedure = ModifyReviewProcedure(presentingViewController: presentingViewController, modificationType: modificationType) { (error) in
            print(error ?? "No Error")
            
            if error == nil {
                
                DispatchQueue.main.async {
                    
                    self.hasPendingReviewModification = true
                    AppDelegate.setNeedsStatusUpdate()
                }
            }
        }
        
        Server.add(procedure: addProcedure)
    }
    
    func scheduleUpdateProcedure(completion: ((UIBackgroundFetchResult) -> Void)? = nil) {
        
        self.isUpdating = true
        
        let statusProcedure = StatusProcedure(presentingViewController: presentingViewController) { (user, reviews, error) in
            
            DispatchQueue.main.async {
                
                if let user = user {
                    
                    let importProcedure = ImportAccountIntoCoreDataProcedure(account: user)
                    
                    importProcedure.addDidFinishBlockObserver { (_, _) in
                        self.isUpdating = false
                    }
                    
                    self.procedureQueue.add(operation: importProcedure)
                }
                
                if let reviews = reviews {
                    
                    let oldReviewsCount = AppDelegate.badgeNumber()?.intValue ?? 0
                    
                    let importProcedure = ImportReviewsIntoCoreDataProcedure(reviews: reviews)
                    
                    importProcedure.addDidFinishBlockObserver { (_, _) in
                        self.isUpdating = false
                        
                        self.startStatusUpdates()
                        
                        if self.hasPendingReviewModification {
                            self.hasPendingReviewModification = false
                            NotificationCenter.default.post(name: .BunProDidModifyReview, object: nil)
                        }
                        
                        DispatchQueue.main.async {
                            let newReviewsCount = AppDelegate.badgeNumber()?.intValue ?? 0
                            let hasNewReviews = newReviewsCount > oldReviewsCount
                            if hasNewReviews {
                                UserNotificationCenter.shared.scheduleNextReviewNotification(at: Date().addingTimeInterval(1.0), reviewCount: newReviewsCount)
                            }
                            
                            completion?(hasNewReviews ? .newData : .noData)
                        }
                    }
                    
                    self.procedureQueue.add(operation: importProcedure)
                }
            }
        }
        
        Server.add(procedure: statusProcedure)
    }
}

extension Notification.Name {
    
    static let BunProWillBeginUpdating = Notification.Name(rawValue: "BunProWillBeginUpdating")
    static let BunProDidEndUpdating = Notification.Name(rawValue: "BunProDidEndUpdating")
}

extension Notification.Name {
    
    static let BunProDidModifyReview = Notification.Name(rawValue: "BunProDidModifyReview")
}
