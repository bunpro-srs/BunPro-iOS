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
    
    init(stack: CoreDataStack = AppDelegate.coreDataStack, user: User) {
        
        self.stack = stack
        self.user = user
        
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
            
            do {
                try context.save()
                DispatchQueue.main.async {
                    self.stack.save()
                    self.finish()
                }
            } catch {
                self.finish(withError: error)
            }
        }
    }
}
