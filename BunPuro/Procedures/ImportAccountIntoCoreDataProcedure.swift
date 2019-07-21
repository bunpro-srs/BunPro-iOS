//
//  Created by Andreas Braun on 06.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import Foundation
import ProcedureKit

final class ImportAccountIntoCoreDataProcedure: Procedure {
    let stack: CoreDataStack
    let account: BPKAccount
    let progress: BPKAccountProgress?

    init(account: BPKAccount, progress: BPKAccountProgress? = nil, stack: CoreDataStack = AppDelegate.coreDataStack) {
        self.stack = stack
        self.account = account
        self.progress = progress

        super.init()
    }

    override func execute() {
        guard !isCancelled else { return }

        stack.storeContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            _ = Account(account: self.account, context: context)

            do {
                try context.save()
                self.finish()
            } catch {
                self.finish(with: error)
            }
        }
    }
}
