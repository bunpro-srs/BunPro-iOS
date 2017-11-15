//
//  StatusProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

class StatusProcedure: GroupProcedure, OutputProcedure {
        
    var output: Pending<ProcedureResult<(UserResponse, UserProgress, ReviewResponse)>> = .pending
    
    let completion: ((UserResponse?, UserProgress?, ReviewResponse?, Error?) -> Void)?
    var indicator: NetworkActivityIndicatorProtocol? {
        didSet {
            guard let indicator = indicator else { return }
            add(observer: NetworkObserver(controller: NetworkActivityController(timerInterval: 1.0, indicator: indicator)))
        }
    }
    
    private let _userNetworkProcedure = UserProcedure()
    private let _progressNetworkProcedure = ProgressProcedure()
    private let _reviewsNetworkProcedure = ReviewsProcedure()
    
    init(completion: ((UserResponse?, UserProgress?, ReviewResponse?, Error?) -> Void)? = nil) {
        
        self.completion = completion
        
        super.init(operations: [_userNetworkProcedure, _progressNetworkProcedure, _reviewsNetworkProcedure])
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        guard let userResponse = _userNetworkProcedure.output.value?.value,
            let userProgress = _progressNetworkProcedure.output.value?.value,
            let reviewResponse = _reviewsNetworkProcedure.output.value?.value else {
                output = Pending.ready(ProcedureResult.failure(withErrors.first ?? ServerError.unknown))
                completion?(nil, nil, nil, withErrors.first)
                
                return
        }
        
        output = Pending.ready(ProcedureResult.success((userResponse, userProgress, reviewResponse)))
        
        completion?(userResponse, userProgress, reviewResponse, nil)
    }
}
