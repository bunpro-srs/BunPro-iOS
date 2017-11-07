//
//  UserProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

let usersUrlString = "\(baseUrlString)users/"

class UserProcedure: GroupProcedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<UserResponse>> = .pending
    
    let completion: ((UserResponse?, Error?) -> Void)?
    
    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>
    private let _transformProcedure: TransformProcedure<Data, UserResponse>
    
    init(completion: ((UserResponse?, Error?) -> Void)? = nil) {
        
        let url = URL(string: usersUrlString + Server.apiToken)!
        let request = URLRequest(url: url)
        
        _networkProcedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, UserResponse> { try CustomDecoder.decode(UserResponse.self, from: $0) }
        _transformProcedure.injectPayload(fromNetwork: _networkProcedure)
        
        self.completion = completion
        
        super.init(operations: [_networkProcedure, _transformProcedure])
        
        self.add(observer: NetworkObserver(controller: NetworkActivityController(timerInterval: 1.0, indicator: UIApplication.shared)))
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        
        print(errors)
        output = _transformProcedure.output
        
        completion?(output.value?.value, output.error)
    }
}
