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
    
    static var token: Token?
    
    public static func add(procedure: Procedure) {
        NetworkHandler.shared.queue.add(operation: procedure)
    }
        
//    public static func updateStatus(indicator: NetworkActivityIndicatorProtocol?, completion: @escaping (Error?) -> Void) {
//
//        guard let token = token else {
//
//            DispatchQueue.main.async {
//                completion(ServerError.noAPIToken)
//            }
//            return
//        }
//
//        let statusProcedure = StatusProcedure(token: token) { (user, userProgress, reviewResponse, error) in
//
//            DispatchQueue.main.async {
//                self.user = user
//                self.userProgress = userProgress
//                self.reviewResponse = reviewResponse
//                completion(error)
//            }
//        }
//
//        statusProcedure.indicator = indicator
//
//        NetworkHandler.shared.queue.add(operation: statusProcedure)
//    }
//
//    public static func updateJLPT(completion: @escaping ([JLPT]?, Error?) -> Void) {
//
//        guard let token = token else {
//
//            DispatchQueue.main.async {
//                completion(nil, ServerError.noAPIToken)
//            }
//            return
//        }
//
//        let grammarProcedure = LessonsProcedure(token: token) { (jlpts, error) in
//
//            DispatchQueue.main.async {
//                completion(jlpts, error)
//            }
//        }
//
//        NetworkHandler.shared.queue.add(operation: grammarProcedure)
//    }
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
