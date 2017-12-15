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
import KeychainAccess

let baseUrlString = "https://bunpro.jp/api/v2/"

/*
 bunpro.jp/api/v1/users/[:key]                  <- Gets user info
 bunpro.jp/api/v1/users/[:key]/user_progress    <- Gets lesson progress
 bunpro.jp/api/v1/users/[:key]/all_reviews      <- Gets all reviews for user
 bunpro.jp/api/v1/users/[:key]/current_reviews  <- Gets current reviews
 bunpro.jp/api/v1/grammar_points/[:key]         <- Gets all grammar points
 bunpro.jp/api/v1/lessons/[:token]              <- Gets all lessons
 */

enum ServerError: Error {
    case noAPIToken
    case unknown
}

public struct Server {
    
    public static var user: User?
    public static var userProgress: UserProgress?
    public static var reviewResponse: ReviewResponse?
    
    static var token: Token? {
        get {
            return _token ?? Keychain()[string: LoginViewController.CredentialsKey.token.rawValue]
        }
        
        set {
            _token = newValue
            Keychain()[LoginViewController.CredentialsKey.token.rawValue] = newValue
        }
    }
    
    static private var _token: Token?
    
    public static func reset() {
        token = nil
    }
    
    public static func add(procedure: Procedure) {
        NetworkHandler.shared.queue.add(operation: procedure)
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

extension UIApplication: NetworkActivityIndicatorProtocol { }
