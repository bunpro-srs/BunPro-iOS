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

private let usersUrlString = "\(baseUrlString)user/"

public class UserProcedure: GroupProcedure, OutputProcedure {
    
    public var output: Pending<ProcedureResult<User>> = .pending
    
    public let completion: ((User?, Error?) -> Void)?
    
    private var _internalProcedure: _UserProcedure!
    
    public init(presentingViewController: UIViewController, completion: ((User?, Error?) -> Void)? = nil) {
        
        self.completion = completion
        
        super.init(operations: [])
        
        add(condition: LoggedInCondition(presentingViewController: presentingViewController))
        
        addWillExecuteBlockObserver { (_, _) in
            self._internalProcedure = _UserProcedure()
            self.add(child: self._internalProcedure)
        }
    }
    
    override public func procedureDidFinish(withErrors: [Error]) {
        output = _internalProcedure.output
        completion?(output.value?.value, output.error)
    }
}

class _UserProcedure: GroupProcedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<User>> = .pending
    
    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>
    private let _transformProcedure: TransformProcedure<Data, User>
    
    init() {
        
        let url = URL(string: usersUrlString)!
        var request = URLRequest(url: url)
        
        request.setValue("Token token=\(Server.token!)", forHTTPHeaderField: "Authorization")
        
        _networkProcedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, User> { try CustomDecoder.decode(User.self, from: $0) }
        _transformProcedure.injectPayload(fromNetwork: _networkProcedure)
        
        super.init(operations: [_networkProcedure, _transformProcedure])
    }
        
    override func procedureDidFinish(withErrors: [Error]) {
        print(errors)
        output = _transformProcedure.output
    }
}
