//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import Foundation
import KeychainAccess
import ProcedureKit


let websiteUrlString = "https://bunpro.jp"
let baseUrlString = "https://bunpro.jp/api/v3/"

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

public enum Server {
    static var token: Token? {
        get { _token ?? Keychain()[string: CredentialKey.token] }

        set {
            _token = newValue
            Keychain()[CredentialKey.token] = newValue
        }
    }

    private static var _token: Token?

    public static func reset() {
        token = nil
    }

    public static func logout() {
        add(procedure: LogoutProcedure())
    }

    public static func add(procedure: Procedure) {
        NetworkHandler.shared.queue.addOperation(procedure)
    }
}

final class NetworkHandler {
    static let shared = NetworkHandler()

    let queue = ProcedureQueue()
}

enum CustomDecoder {
    static func decode<T>(_ type: T.Type, from data: Data, hasMilliseconds: Bool = false) throws -> T where T: Decodable {
        let formatter = DateFormatter()

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
