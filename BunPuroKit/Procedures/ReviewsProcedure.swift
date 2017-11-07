//
//  ReviewsProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

class ReviewsProcedure: GroupProcedure, OutputProcedure {
    
    enum Collection: String {
        case all = "all_reviews"
        case current = "current_reviews"
    }
    
    var output: Pending<ProcedureResult<ReviewResponse>> = .pending
    
    let completion: ((ReviewResponse?, Error?) -> Void)?
    
    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>
    private let _transformProcedure: TransformProcedure<Data, ReviewResponse>
    
    init(collection: Collection = .all, completion: ((ReviewResponse?, Error?) -> Void)? = nil) {
        
        let url = URL(string: usersUrlString + Server.apiToken + "/" + collection.rawValue)!
        let request = URLRequest(url: url)
        
        _networkProcedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, ReviewResponse> { try CustomDecoder.decode(ReviewResponse.self, from: $0, hasMilliseconds: true) }
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
