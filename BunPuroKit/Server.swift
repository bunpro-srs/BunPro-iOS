//
//  Server.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

/*
 bunpro.jp/api/v1/users/[:key]                  <- Gets user info
 bunpro.jp/api/v1/users/[:key]/user_progress    <- Gets lesson progress
 bunpro.jp/api/v1/users/[:key]/all_reviews      <- Gets all reviews for user
 bunpro.jp/api/v1/users/[:key]/current_reviews  <- Gets current reviews
 bunpro.jp/api/v1/grammar_points/[:key]         <- Gets all grammar points
 */

public struct Server {
    
    enum ServerError: Error {
        case noAPIToken
    }
    
    public static var apiToken: String!
    
    public static var userResponse: UserResponse?
    public static var userProgress: UserProgress?
    public static var reviewResponse: ReviewResponse?
    
    public static func updatedUser(completion: @escaping (Error?) -> Void) {
        
        guard apiToken != nil else {
            
            DispatchQueue.main.async {
                completion(ServerError.noAPIToken)
            }
            return
        }
        
        let userProcedure = UserProcedure { (response, error) in
            
            DispatchQueue.main.async {
                self.userResponse = response
                completion(error)
            }
        }
        
        NetworkHandler.shared.queue.add(operation: userProcedure)
    }
    
    public static func updatedStatus(completion: @escaping (Error?) -> Void) {
        
        guard apiToken != nil else {
            
            DispatchQueue.main.async {
                completion(ServerError.noAPIToken)
            }
            return
        }
        
        let statusProcedure = StatusProcedure { (userResponse, userProgress, reviewResponse, error) in
            
            DispatchQueue.main.async {
                self.userResponse = userResponse
                self.userProgress = userProgress
                self.reviewResponse = reviewResponse
                completion(error)
            }
        }
        
        NetworkHandler.shared.queue.add(operation: statusProcedure)
    }
}

class NetworkHandler {
    
    static let shared: NetworkHandler = NetworkHandler()
    
    let queue = ProcedureQueue()
    
    init() { }
}

struct CustomDecoder {
    
    static private let formatter = DateFormatter()
    
    static func decode<T>(_ type: T.Type, from data: Data, hasMilliseconds: Bool = false) throws -> T where T : Decodable {
        
        formatter.locale = Locale(identifier: "en_US")

        if hasMilliseconds {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        } else {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        
        return try decoder.decode(type, from: data)
    }
}

let baseUrlString = "https://bunpro.jp/api/v1/"
let usersUrlString = "\(baseUrlString)users/"
let reviewUrlString = "\(baseUrlString)reviews/"

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
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        
        print(errors)
        output = _transformProcedure.output
        
        completion?(output.value?.value, output.error)
    }
}

class ProgressProcedure: GroupProcedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<UserProgress>> = .pending
    
    let completion: ((UserProgress?, Error?) -> Void)?
    
    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>
    private let _transformProcedure: TransformProcedure<Data, UserProgress>
    
    init(completion: ((UserProgress?, Error?) -> Void)? = nil) {
        
        let url = URL(string: usersUrlString + Server.apiToken + "/user_progress")!
        let request = URLRequest(url: url)
        
        _networkProcedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, UserProgress> { try CustomDecoder.decode(UserProgress.self, from: $0) }
        _transformProcedure.injectPayload(fromNetwork: _networkProcedure)
        
        self.completion = completion
        
        super.init(operations: [_networkProcedure, _transformProcedure])
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        
        print(errors)
        output = _transformProcedure.output
        
        completion?(output.value?.value, output.error)
    }
}

class ReviewsProcedure: GroupProcedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<ReviewResponse>> = .pending
    
    let completion: ((ReviewResponse?, Error?) -> Void)?
    
    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>
    private let _transformProcedure: TransformProcedure<Data, ReviewResponse>
    
    init(completion: ((ReviewResponse?, Error?) -> Void)? = nil) {
        
        let url = URL(string: usersUrlString + Server.apiToken + "/all_reviews")!
        let request = URLRequest(url: url)
        
        _networkProcedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, ReviewResponse> { try CustomDecoder.decode(ReviewResponse.self, from: $0, hasMilliseconds: true) }
        _transformProcedure.injectPayload(fromNetwork: _networkProcedure)
        
        self.completion = completion
        
        super.init(operations: [_networkProcedure, _transformProcedure])
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        
        print(errors)
        output = _transformProcedure.output
        
        completion?(output.value?.value, output.error)
    }
}

class StatusProcedure: GroupProcedure, OutputProcedure {
    
    enum StatusError: Error {
        case unknown
    }
    
    var output: Pending<ProcedureResult<(UserResponse, UserProgress, ReviewResponse)>> = .pending
    
    let completion: ((UserResponse?, UserProgress?, ReviewResponse?, Error?) -> Void)?
    
    private let _userNetworkProcedure = UserProcedure()
    private let _progressNetworkProcedure = ProgressProcedure()
    private let _reviewsNetworkProcedure = ReviewsProcedure()
    
    init(completion: ((UserResponse?, UserProgress?, ReviewResponse?, Error?) -> Void)? = nil) {
        
        self.completion = completion
        
        super.init(operations: [_userNetworkProcedure, _progressNetworkProcedure, _reviewsNetworkProcedure])
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        guard let userResponse = _userNetworkProcedure.output.value?.value,
            let userProgress = _progressNetworkProcedure.output.value?.value,
            let reviewResponse = _reviewsNetworkProcedure.output.value?.value else {
                output = Pending.ready(ProcedureResult.failure(withErrors.first ?? StatusError.unknown))
                completion?(nil, nil, nil, withErrors.first)
                
                return
        }
        
        output = Pending.ready(ProcedureResult.success((userResponse, userProgress, reviewResponse)))
        
        completion?(userResponse, userProgress, reviewResponse, nil)
    }
}
