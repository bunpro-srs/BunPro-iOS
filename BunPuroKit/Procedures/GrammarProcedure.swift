//
//  GrammarProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 08.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

class GrammarProcedure: GroupProcedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<([JLPT])>> = .pending
    
    let completion: (([JLPT]?, Error?) -> Void)?
    
    private let _lessonsNetworkProcedure = LessonsProcedure()
    
    init(completion: (([JLPT]?, Error?) -> Void)? = nil) {
        
        self.completion = completion
        
        super.init(operations: [_lessonsNetworkProcedure])
        
        self.add(observer: NetworkObserver(controller: NetworkActivityController(timerInterval: 1.0, indicator: UIApplication.shared)))
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        guard
            let lessonResponse = _lessonsNetworkProcedure.output.value?.value
            else {
                output = Pending.ready(ProcedureResult.failure(withErrors.first ?? ServerError.unknown))
                completion?(nil, withErrors.first)
                
                return
        }
        
        output = Pending.ready(ProcedureResult.success((lessonResponse)))
        
        completion?(lessonResponse, nil)
    }
}
