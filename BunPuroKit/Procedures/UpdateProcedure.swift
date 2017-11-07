//
//  UpdateProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

class UpdateProcedure: GroupProcedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<(UserResponse, UserProgress, ReviewResponse, LessonResponse, GrammarPointResponse)>> = .pending
    
    let completion: ((UserResponse?, UserProgress?, ReviewResponse?, LessonResponse?, GrammarPointResponse?, Error?) -> Void)?
    
    private let _userNetworkProcedure = UserProcedure()
    private let _progressNetworkProcedure = ProgressProcedure()
    private let _reviewsNetworkProcedure = ReviewsProcedure()
    private let _lessonsNetworkProcedure = LessonsProcedure()
    private let _grammarPointsNetworkProcedure = GrammarPointsProcedure()
    
    init(completion: ((UserResponse?, UserProgress?, ReviewResponse?, LessonResponse?, GrammarPointResponse?, Error?) -> Void)? = nil) {
        
        self.completion = completion
        
        super.init(operations: [_userNetworkProcedure,
                                _progressNetworkProcedure,
                                _reviewsNetworkProcedure,
                                _lessonsNetworkProcedure,
                                _grammarPointsNetworkProcedure])
        
        self.add(observer: NetworkObserver(controller: NetworkActivityController(timerInterval: 1.0, indicator: UIApplication.shared)))
        
        maxConcurrentOperationCount = 1
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        guard let userResponse = _userNetworkProcedure.output.value?.value,
            let userProgress = _progressNetworkProcedure.output.value?.value,
            let reviewResponse = _reviewsNetworkProcedure.output.value?.value,
            let lessonResponse = _lessonsNetworkProcedure.output.value?.value,
            let grammarResponse = _grammarPointsNetworkProcedure.output.value?.value
            else {
                output = Pending.ready(ProcedureResult.failure(withErrors.first ?? ServerError.unknown))
                completion?(nil, nil, nil, nil, nil, withErrors.first)
                
                return
        }
        
        output = Pending.ready(ProcedureResult.success((userResponse, userProgress, reviewResponse, lessonResponse, grammarResponse)))
        
        completion?(userResponse, userProgress, reviewResponse, lessonResponse, grammarResponse, nil)
    }
}
