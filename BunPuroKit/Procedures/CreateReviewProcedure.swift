//
//  CreateReviewProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 23.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

public final class CreateReviewProcedure: GroupProcedure {
    
    public let completion: ((Error?) -> Void)
    public let presentingViewController: UIViewController
    
    private let grammarIdentifier: Int64
    private let complete: Bool
    
    private var _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>!
    
    public init(presentingViewController: UIViewController, grammarIdentifier: Int64, complete: Bool, completion: @escaping ((Error?) -> Void)) {
        
        self.completion = completion
        self.presentingViewController = presentingViewController
        
        self.grammarIdentifier = grammarIdentifier
        self.complete = complete
        
        super.init(operations: [])
        
        add(condition: LoggedInCondition(presentingViewController: presentingViewController))
    }
    
    override public func execute() {
        
        guard !isCancelled else { return }
        
        var components = URLComponents(string: "https://bunpro.jp/api/v3/reviews/create/\(grammarIdentifier)")!
        components.queryItems = [
            URLQueryItem(name: "complete", value: "\(complete)")
        ]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        request.setValue("Token token=\(Server.token!)", forHTTPHeaderField: "Authorization")
        
        _networkProcedure = NetworkProcedure(resilience: DefaultNetworkResilience(requestTimeout: nil)) { NetworkDataProcedure(session: URLSession.shared, request: request) }
        
        add(child: _networkProcedure)
        
        super.execute()
    }
    
    public override func procedureDidFinish(withErrors: [Error]) {
        
        completion(withErrors.first)
    }
}
