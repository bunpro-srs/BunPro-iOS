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
    private let updateTimeInterval: TimeInterval = TimeInterval(60)
    private var startImmediately: Bool = true
    private var isUpdating: Bool = false {
        
        didSet {
            DispatchQueue.main.async {
                
                NotificationCenter.default.post(name: self.isUpdating ? .BunProWillBeginUpdating : .BunProDidEndUpdating, object: self)
            }
        }
    }
    private weak var statusUpdateTimer: Timer? { didSet { statusUpdateTimer?.tolerance = 10.0 } }
    
    func startStatusUpdates() {
        
        if startImmediately {
            startImmediately = false
            scheduleUpdateProcedure()
        }
        
        guard !isUpdating else { return }
        
        stopStatusUpdates()
        
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateTimeInterval, repeats: true) { (_) in
            
            guard !self.isUpdating else { return }
            self.isUpdating = true
            self.scheduleUpdateProcedure()
        }
    }
    
    func stopStatusUpdates() {
        
        statusUpdateTimer?.invalidate()
    }
    
    func updateGrammarDatabase() {
        
        // updates the grammar database
    }
    
    private func scheduleUpdateProcedure() {
        
        let statusProcedure = StatusProcedure(presentingViewController: presentingViewController) { (user, progress, reviews, error) in
            
            DispatchQueue.main.async {
                
                defer {
                    self.isUpdating = false
                }
                
                if let user = user, let progress = progress {
                    
                    print("Saving the user: \(user.name)")
                    
                    let importProcedure = ImportAccountIntoCoreDataProcedure(account: user, progress: progress)
                    
                    self.procedureQueue.add(operation: importProcedure)
                }
                
                if let reviews = reviews {
                    
                    print("Saving reviews")
                    
                    let importProcedure = ImportReviewsIntoCoreDataProcedure(reviews: reviews)
                    
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
