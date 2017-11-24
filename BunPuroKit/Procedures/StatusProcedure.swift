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

public class StatusProcedure: GroupProcedure, OutputProcedure {
        
    public var output: Pending<ProcedureResult<(User, UserProgress, ReviewResponse)>> = .pending
    
    public let completion: ((User?, UserProgress?, ReviewResponse?, Error?) -> Void)?
    public var indicator: NetworkActivityIndicatorProtocol? {
        didSet {
            guard let indicator = indicator else { return }
            add(observer: NetworkObserver(controller: NetworkActivityController(timerInterval: 1.0, indicator: indicator)))
        }
    }
    
    private let _userNetworkProcedure: UserProcedure
    private let _progressNetworkProcedure: ProgressProcedure
    private let _reviewsNetworkProcedure: ReviewsProcedure
    
    public init(presentingViewController: UIViewController, completion: ((User?, UserProgress?, ReviewResponse?, Error?) -> Void)? = nil) {
        
        _userNetworkProcedure = UserProcedure(presentingViewController: presentingViewController)
        _progressNetworkProcedure = ProgressProcedure(presentingViewController: presentingViewController)
        _progressNetworkProcedure.add(dependency: _userNetworkProcedure)
        _reviewsNetworkProcedure = ReviewsProcedure(presentingViewController: presentingViewController)
        _reviewsNetworkProcedure.add(dependency: _userNetworkProcedure)
        self.completion = completion
        
        super.init(operations: [_userNetworkProcedure, _progressNetworkProcedure, _reviewsNetworkProcedure])
    }
    
    override public func procedureDidFinish(withErrors: [Error]) {
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
