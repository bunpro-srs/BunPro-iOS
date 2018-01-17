//
//  ImportAccountIntoCoreDataProcedure.swift
//  BunPuro
//
//  Created by Andreas Braun on 06.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import BunPuroKit
import ProcedureKit
import CoreData

class ImportAccountIntoCoreDataProcedure: Procedure {
    
    let stack: CoreDataStack
    let user: User
    let progress: UserProgress?
    
    init(stack: CoreDataStack = AppDelegate.coreDataStack, user: User, progress: UserProgress? = nil) {
        
        self.stack = stack
        self.user = user
        self.progress = progress
        
        super.init()
    }
    
    override func execute() {
        guard !isCancelled else { return }
        
        stack.storeContainer.performBackgroundTask { (context) in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            let newAccount = Account(context: context)
            
            newAccount.name = self.user.name
            newAccount.isActivated = self.user.isActivated
            newAccount.createdDate = self.user.createdAt
            newAccount.updatedDate = self.user.updatedAt
            newAccount.bunnyMode = self.user.bunnyMode == State.on
            newAccount.furiganaMode = self.user.furigana.rawValue
            newAccount.englishMode = self.user.hideEnglish == Active.yes
            newAccount.lightMode = self.user.lightMode == State.on
            
            if let progress = self.progress {
                self.addLevel(progress.n5, to: newAccount, in: context)
                self.addLevel(progress.n4, to: newAccount, in: context)
                self.addLevel(progress.n3, to: newAccount, in: context)
            }
            do {
                try context.save()
                self.finish()
            } catch {
                self.finish(withError: error)
            }
        }
    }
    
    private func addLevel(_ level: UserProgress.JLPT, to account: Account, in managedObjectContext: NSManagedObjectContext) {
        let newLevel = Level(context: managedObjectContext)
        
        newLevel.name = level.name
        newLevel.current = Int16(level.current)
        newLevel.max = Int16(level.max)
        newLevel.account = account
    }
}
