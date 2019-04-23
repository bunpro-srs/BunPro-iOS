//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import BunPuroKit
import CoreData
import Foundation

extension Account {
    convenience init(account: BPKAccount, context: NSManagedObjectContext) {
        self.init(context: context)

        identifier = account.identifier
        name = account.name
        bunnyMode = account.bunnyMode == State.on
        furiganaMode = account.furigana.rawValue
        englishMode = account.hideEnglish == Active.yes
        reviewEnglishMode = account.reviewEnglish.rawValue
        subscriber = account.subscriber
    }
}

extension Account {
    static var currentAccount: Account? {
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.fetchBatchSize = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Account.name), ascending: true)]

        do {
            return try AppDelegate.coreDataStack.managedObjectContext.fetch(fetchRequest).first
        } catch {
            log.error(error)
            return nil
        }
    }
}
