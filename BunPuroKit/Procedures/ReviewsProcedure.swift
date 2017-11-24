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

public enum ReviewCollection {
    case all
    case current
    
    var rawValue: String {
        switch self {
        case .all: return "all_reviews"
        case .current: return "current_reviews"
        }
    }
}

public class ReviewsProcedure: GroupProcedure, OutputProcedure {
    
    public var output: Pending<ProcedureResult<ReviewResponse>> = .pending
    
    let completion: ((ReviewResponse?, Error?) -> Void)?
    
    private var _internalProcedure: _ReviewsProcedure!
    
    init(presentingViewController: UIViewController, collection: ReviewCollection = .all, completion: ((ReviewResponse?, Error?) -> Void)? = nil) {
        self.completion = completion
        
        super.init(operations: [])
        
        add(condition: LoggedInCondition(presentingViewController: presentingViewController))
        
        addWillExecuteBlockObserver { (_, _) in
            self._internalProcedure = _ReviewsProcedure(collection: collection)
            self.add(child: self._internalProcedure)
        }
    }
    
    override public func procedureDidFinish(withErrors: [Error]) {
        output = _internalProcedure.output
        completion?(output.value?.value, output.error)
    }
}

class _ReviewsProcedure: GroupProcedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<ReviewResponse>> = .pending
    
    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>
    private let _transformProcedure: TransformProcedure<Data, ReviewResponse>
    
    init(collection: ReviewCollection = .all) {
        
        let url = URL(string: baseUrlString + "/" + collection.rawValue)!
        
        var request = URLRequest(url: url)
        request.setValue("Token token=\(Server.token!)", forHTTPHeaderField: "Authorization")
        
        _networkProcedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, ReviewResponse> { try CustomDecoder.decode(ReviewResponse.self, from: $0, hasMilliseconds: true) }
        _transformProcedure.injectPayload(fromNetwork: _networkProcedure)
        
        super.init(operations: [_networkProcedure, _transformProcedure])
        
        self.add(observer: NetworkObserver(controller: NetworkActivityController(timerInterval: 1.0, indicator: UIApplication.shared)))
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        
        print(errors)
        output = _transformProcedure.output
    }
}
