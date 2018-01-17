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
    
    init(presentingViewController: UIViewController, persistentContainer: NSPersistentContainer = AppDelegate.coreDataStack.storeContainer) {
        self.presentingViewController = presentingViewController
        self.persistentContainer = persistentContainer
    }
    
    // Status Updates
    private let updateTimeInterval: TimeInterval = TimeInterval(60)
    private var startImmediately: Bool = true
    private var isUpdating: Bool = false
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
            
            defer {
                self.isUpdating = false
            }
            
            DispatchQueue.main.async {
                
                if let user = user, let progress = progress {
                    
                    print("Saving the user: \(user.name)")
                    
                    let userProcedure = ImportAccountIntoCoreDataProcedure(user: user, progress: progress)
                    
                    self.procedureQueue.add(operation: userProcedure)
                }
            }
        }
        
        Server.add(procedure: statusProcedure)
    }
}
