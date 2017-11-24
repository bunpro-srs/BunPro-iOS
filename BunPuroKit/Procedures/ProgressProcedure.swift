//
//  ProgressProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

private let progressUrlString = baseUrlString + "/user_progress"

public class ProgressProcedure: GroupProcedure, OutputProcedure {
    
    public var output: Pending<ProcedureResult<UserProgress>> = .pending
    
    public let completion: ((UserProgress?, Error?) -> Void)?
    
    private var _internalProcedure: _ProgressProcedure!
    
    public init(presentingViewController: UIViewController, completion: ((UserProgress?, Error?) -> Void)? = nil) {
        self.completion = completion
        
        super.init(operations: [])
        
        add(condition: LoggedInCondition(presentingViewController: presentingViewController))
        
        addWillExecuteBlockObserver { (_, _) in
            self._internalProcedure = _ProgressProcedure()
            self.add(child: self._internalProcedure)
        }
    }
    
    override public func procedureDidFinish(withErrors: [Error]) {
        output = _internalProcedure.output
        completion?(output.value?.value, output.error)
    }
}

class _ProgressProcedure: GroupProcedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<UserProgress>> = .pending
    
    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>
    private let _transformProcedure: TransformProcedure<Data, UserProgress>
    
    init() {
        
        let url = URL(string: progressUrlString)!
        
        var request = URLRequest(url: url)
        request.setValue("Token token=\(Server.token!)", forHTTPHeaderField: "Authorization")
        
        _networkProcedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, UserProgress> { try CustomDecoder.decode(UserProgress.self, from: $0) }
        _transformProcedure.injectPayload(fromNetwork: _networkProcedure)
        
        super.init(operations: [_networkProcedure, _transformProcedure])
        
        self.add(observer: NetworkObserver(controller: NetworkActivityController(timerInterval: 1.0, indicator: UIApplication.shared)))
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        print(errors)
        output = _transformProcedure.output
    }
}
