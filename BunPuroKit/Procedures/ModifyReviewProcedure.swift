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

public final class ModifyReviewProcedure: GroupProcedure {
    
    enum ModificationError: Error {
        case noToken
    }
    
    public enum ModificationType {
        /// Provide the Grammar identifier
        case add(Int64)
        /// Provide the Review identifier
        case remove(Int64)
        /// Provide the Review identifier
        case reset(Int64)
    }
    
    public let completion: ((Error?) -> Void)
    public let presentingViewController: UIViewController
    
    private let modificationType: ModificationType
    
    private var _networkProcedure: NetworkProcedure<NetworkDataProcedure>!
    
    public init(presentingViewController: UIViewController, modificationType: ModificationType, completion: @escaping ((Error?) -> Void)) {
        
        self.completion = completion
        self.presentingViewController = presentingViewController
        
        self.modificationType = modificationType
        
        super.init(operations: [])
        
        addCondition(LoggedInCondition(presentingViewController: presentingViewController))
    }
    
    override public func execute() {
        
        guard !isCancelled else { return }
        guard let token = Server.token else { finish(with: ModificationError.noToken); return }
        
        let urlString: String
        var components: URLComponents
        
        switch modificationType {
        case .add(let identifier):
            urlString = "https://bunpro.jp/api/v3/reviews/create/\(identifier)"
            
            components = URLComponents(string: urlString)!
            components.queryItems = [
                URLQueryItem(name: "complete", value: "\(true)")
            ]
            
        case .remove(let identifier):
            urlString = "https://bunpro.jp/api/v3/reviews/edit/\(identifier)"
            
            components = URLComponents(string: urlString)!
            components.queryItems = [
                URLQueryItem(name: "remove_review", value: "\(true)")
            ]
            
        case .reset(let identifier):
            urlString = "https://bunpro.jp/api/v3/reviews/edit/\(identifier)"
            
            components = URLComponents(string: urlString)!
            components.queryItems = [
                URLQueryItem(name: "reset", value: "\(true)")
            ]
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        request.setValue("Token token=\(token)", forHTTPHeaderField: "Authorization")
        
        _networkProcedure = NetworkProcedure(resilience: DefaultNetworkResilience(requestTimeout: nil)) { NetworkDataProcedure(session: URLSession.shared, request: request) }
        
        addChild(_networkProcedure)
        
        super.execute()
    }
    
    public override func procedureDidFinish(with error: Error?) {
        
        completion(error)
    }
}
