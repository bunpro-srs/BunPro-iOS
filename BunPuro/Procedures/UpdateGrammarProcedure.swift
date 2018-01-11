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

class UpdateGrammarProcedure: GroupProcedure {
    
    private let lessonProcedure: LessonsProcedure
    private let importProcedure: ImportLessonsIntoCoreDataProcedure
    
    init(presentingViewController: UIViewController, initialImport: Bool = false) {
        
        lessonProcedure = LessonsProcedure(presentingViewController: presentingViewController, initialImport: initialImport)
        importProcedure = ImportLessonsIntoCoreDataProcedure()
        importProcedure.injectResult(from: lessonProcedure)
        
        super.init(operations: [lessonProcedure, importProcedure])
        
        self.name = "Update Grammar"
    }
}

fileprivate class ImportLessonsIntoCoreDataProcedure: Procedure, InputProcedure {
    
    var input: Pending<[BunPuroKit.JLPT]> = .pending
    
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

            jlpts.forEach { (jlpt) in

                let newJPLT = JLPT(context: context)

                newJPLT.level = Int64(jlpt.level)
                newJPLT.name = jlpt.name

                jlpt.lessons.forEach { (lesson) in

                    let newLesson = Lesson(context: context)

                    newLesson.id = lesson.id
                    newLesson.order = Int64(lesson.order)
                    newLesson.jlpt = newJPLT

                    lesson.grammar.forEach { (grammar) in

                        let newGrammar = Grammar(context: context)

                        newGrammar.id = grammar.id
                        newGrammar.lesson = newLesson
                        newGrammar.title = grammar.title.htmlAttributedString?.string
                        newGrammar.meaning = grammar.meaning.htmlAttributedString?.string
                        newGrammar.caution = grammar.caution.htmlAttributedString?.string
                        newGrammar.structure = grammar.structure.htmlAttributedString?.string

                        for link in grammar.supplementalLinks {

                            let newLink = Link(context: context)
                            newLink.id = link.id
                            newLink.about = link.description
                            newLink.site = link.site
                            newLink.url = URL(string: link.link.trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
                            newLink.grammar = newGrammar
                        }
                        
                        for sentence in grammar.exampleSentences {
                            
                            let newSentence = Sentence(context: context)
                            newSentence.id = sentence.id
                            newSentence.japanese = sentence.japanese
                            newSentence.english = sentence.english
                            newSentence.structure = sentence.structure
                            newSentence.grammar = newGrammar
                        }
                    }
                }
            }

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
