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

final class DataManager {
    
    private let procedureQueue = ProcedureQueue()
    
    let presentingViewController: UIViewController
    private let persistentContainer: NSPersistentContainer
    
    private var logoutObserver: NSObjectProtocol?
    
    deinit {
        if logoutObserver != nil {
            NotificationCenter.default.removeObserver(logoutObserver!)
        }
    }
    
    init(presentingViewController: UIViewController, persistentContainer: NSPersistentContainer = AppDelegate.coreDataStack.storeContainer) {
        self.presentingViewController = presentingViewController
        self.persistentContainer = persistentContainer
        
        logoutObserver = NotificationCenter.default.addObserver(forName: .ServerDidLogoutNotification, object: nil, queue: nil) { [weak self] (_) in
            
            self?.scheduleUpdateProcedure()
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
        
        RunLoop.main.add(statusUpdateTimer!, forMode: .defaultRunLoopMode)
    }
    
    func stopStatusUpdates() {
        
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
    }
    
    func immidiateStatusUpdate() {
        
        self.scheduleUpdateProcedure()
    }
    
    func updateGrammarDatabase() {
        
        // updates the grammar database
    }
    
    func modifyReview(_ modificationType: ModifyReviewProcedure.ModificationType) {
        
        let addProcedure = ModifyReviewProcedure(presentingViewController: presentingViewController, modificationType: modificationType) { (error) in
            print(error ?? "No Error")
            
            if error == nil {
                
                DispatchQueue.main.async {
                    
                    AppDelegate.setNeedsStatusUpdate()
                }
            }
        }
        
        Server.add(procedure: addProcedure)
    }
    
    private func scheduleUpdateProcedure() {
        
        self.isUpdating = true
        
        let statusProcedure = StatusProcedure(presentingViewController: presentingViewController) { (user, progress, reviews, error) in
            
            DispatchQueue.main.async {
                
                if let user = user, let progress = progress {
                    
                    print("Saving the user: \(user.name)")
                    
                    let importProcedure = ImportAccountIntoCoreDataProcedure(account: user, progress: progress)
                    
                    importProcedure.addDidFinishBlockObserver { (_, _) in
                        self.isUpdating = false
                    }
                    
                    self.procedureQueue.add(operation: importProcedure)
                }
                
                if let reviews = reviews {
                    
                    print("Saving reviews")
                    
                    let importProcedure = ImportReviewsIntoCoreDataProcedure(reviews: reviews)
                    
                    importProcedure.addDidFinishBlockObserver { (_, _) in
                        self.isUpdating = false
                        
                        self.startStatusUpdates()
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
