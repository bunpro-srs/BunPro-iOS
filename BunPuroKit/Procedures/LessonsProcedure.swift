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

let lessonsUrlString = "\(baseUrlString)lessons/"

class LessonsProcedure: GroupProcedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<LessonResponse>> = .pending
    
    let completion: ((LessonResponse?, Error?) -> Void)?
    
    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>
    private let _transformProcedure: TransformProcedure<Data, LessonResponse>
    
    init(completion: ((LessonResponse?, Error?) -> Void)? = nil) {
        
        let url = URL(string: lessonsUrlString + Server.apiToken)!
        let request = URLRequest(url: url)
        
        _networkProcedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, LessonResponse> { try CustomDecoder.decode(LessonResponse.self, from: $0, hasMilliseconds: true) }
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
