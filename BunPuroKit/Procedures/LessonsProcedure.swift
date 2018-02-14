//
//  LessonsProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

public class LessonsProcedure: GroupProcedure, OutputProcedure {
    
    public var output: Pending<ProcedureResult<[BPKJlpt]>> {
        get { return transformProcedure.output }
        set { assertionFailure("\(#function) should never be called.") }
    }
    
    public let completion: (([BPKJlpt]?, Error?) -> Void)?
    
    private var lessonProcedure: _LessonsProcedure?
    private let transformProcedure: TransformProcedure<[BPKLesson], [BPKJlpt]>
    
    public init(presentingViewController: UIViewController, completion: (([BPKJlpt]?, Error?) -> Void)? = nil) {
        
        self.completion = completion
        
        lessonProcedure = _LessonsProcedure(presentingViewController: presentingViewController)
        transformProcedure = TransformProcedure<[BPKLesson], [BPKJlpt]> { LessonsProcedure.jlpt(from: $0) }
        transformProcedure.injectResult(from: lessonProcedure!)
        
        super.init(operations: [lessonProcedure!, transformProcedure])
    }
    
    private static func jlpt(from lessons: [BPKLesson]) -> [BPKJlpt] {
        
        return [1, 2, 3, 4, 5].map { (level) -> BPKJlpt in BPKJlpt(level: level, lessons: lessons.filter { $0.jlptLevel == level }) }
    }
}

fileprivate class _LessonsProcedure: BunPuroProcedure<[BPKLesson]> {
    
    override var hasMilliseconds: Bool { return true }
    override var url: URL { return URL(string: "\(baseUrlString)lessons")! }
}
