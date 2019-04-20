//
//  Created by Andreas Braun on 06.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import BunPuroKit
import ProcedureKit
import CoreData

final class ImportAccountIntoCoreDataProcedure: Procedure {
    
    let stack: CoreDataStack
    let account: BPKAccount
    let progress: BPKAccountProgress?
    
    init(stack: CoreDataStack = AppDelegate.coreDataStack, account: BPKAccount, progress: BPKAccountProgress? = nil) {
        
        self.stack = stack
        self.account = account
        self.progress = progress
        
        super.init()
    }
    
    override func execute() {
        guard !isCancelled else { return }
        
        stack.storeContainer.performBackgroundTask { (context) in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            let _ = Account(account: self.account, context: context)

            do {
                try context.save()
                self.finish()
            } catch {
                self.finish(with: error)
            }
        }
    }
    
    
}
