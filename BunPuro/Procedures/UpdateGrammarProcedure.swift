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
    
    private let lessonProcedure: LessonsProcedure
    private let importProcedure: ImportLessonsIntoCoreDataProcedure
    
    init(presentingViewController: UIViewController) {
        
        lessonProcedure = LessonsProcedure(presentingViewController: presentingViewController)
        importProcedure = ImportLessonsIntoCoreDataProcedure()
        importProcedure.injectResult(from: lessonProcedure)
        
        super.init(operations: [lessonProcedure, importProcedure])
        
        self.name = "Update Grammar"
    }
}

fileprivate final class ImportLessonsIntoCoreDataProcedure: Procedure, InputProcedure {
    
    var input: Pending<[BPKJlpt]> = .pending
    
    let stack: CoreDataStack
    
    init(stack: CoreDataStack = AppDelegate.coreDataStack) {
        
        self.stack = stack
        
        super.init()
    }
    
    override func execute() {
        
        guard !isCancelled else { return }
        guard let jlpts = input.value else { return }
        
        stack.storeContainer.performBackgroundTask { (context) in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            jlpts.forEach { JLPT(jlpt: $0, context: context) }

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
