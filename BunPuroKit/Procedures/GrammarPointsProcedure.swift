//
//  GrammarPointsProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

let grammarPointsUrlString = "\(baseUrlString)grammar_points/"

class GrammarPointsProcedure: GroupProcedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<GrammarPointResponse>> = .pending
    
    let completion: ((GrammarPointResponse?, Error?) -> Void)?
    
    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>
    private let _transformProcedure: TransformProcedure<Data, GrammarPointResponse>
    
    init(completion: ((GrammarPointResponse?, Error?) -> Void)? = nil) {
        
        let url = URL(string: grammarPointsUrlString + Server.apiToken)!
        let request = URLRequest(url: url)
        
        _networkProcedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, GrammarPointResponse> { try CustomDecoder.decode(GrammarPointResponse.self, from: $0, hasMilliseconds: true) }
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
