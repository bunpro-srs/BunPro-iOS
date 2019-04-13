//
//  UpdateGrammarProcedure.swift
//  BunPuro
//
//  Created by Andreas Braun on 24.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import BunPuroKit
import ProcedureKit
import CoreData

final class UpdateGrammarProcedure: GroupProcedure {
    
    private let lessonProcedure: GrammarPointsProcedure
    private let importProcedure: ImportGrammarPointsIntoCoreDataProcedure
    
    init(presentingViewController: UIViewController) {
        
        lessonProcedure = GrammarPointsProcedure(presentingViewController: presentingViewController)
        importProcedure = ImportGrammarPointsIntoCoreDataProcedure()
        importProcedure.injectResult(from: lessonProcedure)
        
        super.init(operations: [lessonProcedure, importProcedure])
        
        self.name = "Update Grammar"
    }
}

fileprivate final class ImportGrammarPointsIntoCoreDataProcedure: Procedure, InputProcedure {
    
    var input: Pending<[BPKGrammar]> = .pending
    
    let stack: CoreDataStack
    
    init(stack: CoreDataStack = AppDelegate.coreDataStack) {
        
        self.stack = stack
        
        super.init()
    }
    
    override func execute() {
        
        guard !isCancelled else { return }
        guard let grammarPoints = input.value else { return }
        
        stack.storeContainer.performBackgroundTask { (context) in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            grammarPoints.filter({ $0.level != "0" }).forEach { Grammar(grammar: $0, context: context) }

            do {
                try context.save()
                DispatchQueue.main.async {
                    self.stack.save()
                    self.finish()
                }
            } catch {
                self.finish(with: error)
            }
        }
    }
}
