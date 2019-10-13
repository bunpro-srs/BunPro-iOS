//
//  Created by Andreas Braun on 06.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import Foundation
import ProcedureKit

final class ImportAccountIntoCoreDataProcedure: Procedure {
    let stack: NSPersistentContainer
    let account: BPKAccount
    let progress: BPKAccountProgress?

    deinit {
        print("\(self) deinit")
    }

    init(account: BPKAccount, progress: BPKAccountProgress? = nil, stack: NSPersistentContainer = AppDelegate.database.persistantContainer) {
        self.stack = stack
        self.account = account
        self.progress = progress

        super.init()
    }

    override func execute() {
        guard !isCancelled else { return }

        stack.performBackgroundTask { context in
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
