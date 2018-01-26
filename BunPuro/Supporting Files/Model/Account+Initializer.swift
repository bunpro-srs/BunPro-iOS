//
//  Account+Initializer.swift
//  BunPuro
//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Foundation
import CoreData
import BunPuroKit

extension Account {
    
    convenience init(account: BPKAccount, progress: BPKAccountProgress?, context: NSManagedObjectContext) {
        
        self.init(context: context)
        
        identifier = account.identifier
        name = account.name
        bunnyMode = account.bunnyMode == State.on
        furiganaMode = account.furigana.rawValue
        englishMode = account.hideEnglish == Active.yes
        lightMode = account.lightMode == State.on
        
        if let progress = progress {
            self.addLevel(progress.n5, to: self, in: context)
            self.addLevel(progress.n4, to: self, in: context)
            self.addLevel(progress.n3, to: self, in: context)
            self.addLevel(progress.n2, to: self, in: context)
        }
    }
    
    private func addLevel(_ level: BPKAccountProgress.JLPT, to account: Account, in managedObjectContext: NSManagedObjectContext) {
        let newLevel = Level(context: managedObjectContext)
        
        newLevel.name = level.name
        newLevel.current = Int16(level.current)
        newLevel.max = Int16(level.max)
        newLevel.account = account
    }
}
