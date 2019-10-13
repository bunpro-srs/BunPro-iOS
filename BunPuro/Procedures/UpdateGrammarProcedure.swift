//
//  Created by Andreas Braun on 24.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import Foundation
import ProcedureKit
import UIKit

final class UpdateGrammarProcedure: GroupProcedure {
    private let lessonProcedure: GrammarPointsProcedure
    private let importProcedure: BatchImportGrammarPointsIntoCoreDataProcedure

    init(presentingViewController: UIViewController) {
        lessonProcedure = GrammarPointsProcedure(presentingViewController: presentingViewController)
        importProcedure = BatchImportGrammarPointsIntoCoreDataProcedure()
        importProcedure.injectResult(from: lessonProcedure)

        super.init(operations: [lessonProcedure, importProcedure])

        self.name = "Update Grammar"
    }
}

fileprivate final class BatchImportGrammarPointsIntoCoreDataProcedure: GroupProcedure, InputProcedure {
    var input: Pending<[BPKGrammar]> = .pending
    let stack: NSPersistentContainer
    
    init(stack: NSPersistentContainer = AppDelegate.database.persistantContainer) {
        self.stack = stack
        super.init(operations: [])
    }

    override func execute() {
        guard !isCancelled else { return }
        guard let grammarPoints = input.value else { return }

        let batches: [[BPKGrammar]] = grammarPoints.chunked(into: 30)

        batches.forEach { self.addChild(ImportGrammarPointsIntoCoreDataProcedure(stack: stack, grammarPoints: $0)) }

        super.execute()
    }
}

final class ImportGrammarPointsIntoCoreDataProcedure: Procedure {
    let stack: NSPersistentContainer
    let grammarPoints: [BPKGrammar]

    init(stack: NSPersistentContainer, grammarPoints: [BPKGrammar]) {
        self.stack = stack
        self.grammarPoints = grammarPoints
        super.init()
    }

    override func execute() {
        guard !isCancelled else { return }

        stack.performBackgroundTask { context in
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            self.grammarPoints.filter { $0.level != "0" }.forEach { Grammar(grammar: $0, context: context) }

            do {
                try context.save()

                DispatchQueue.main.async {
                    self.finish()
                }
            } catch {
                self.finish(with: error)
            }
        }
    }
}
