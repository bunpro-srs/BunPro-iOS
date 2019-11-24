//
//  File.swift
//  
//
//  Created by Andreas Braun on 02.11.19.
//

#if canImport(Combine)
import Combine
#endif
import Foundation
import UIKit

@available(iOS 13.0, *)
extension Server {
    
    private func topLevelDecoder(hasMilliseconds: Bool = false) -> JSONDecoder {
        
        let formatter = DateFormatter()

        formatter.locale = Locale(identifier: "en_US")

        if hasMilliseconds {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        } else {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)

        return decoder
    }
    
    public func accountPublisher() -> AnyPublisher<BPKAccount, Error> {
        let url = URL(string: "\(baseUrlString)user/")!
        var request = URLRequest(url: url)

        request.setValue("Token token=\(Server.token!)", forHTTPHeaderField: "Authorization")
        
        return URLSession
            .shared
            .dataTaskPublisher(for: request)
            .compactMap { $0.data }
            .decode(type: BPKAccount.self, decoder: topLevelDecoder())
            .eraseToAnyPublisher()
    }
    
//    public func statusPublisher() -> AnyPublisher<(BPKAccount, [BPKReview])?, Error> {
//        let url = URL(string: "\(baseUrlString)user/")!
//        var request = URLRequest(url: url)
//
//        request.setValue("Token token=\(Server.token!)", forHTTPHeaderField: "Authorization")
//
//        return URLSession
//            .shared
//            .dataTaskPublisher(for: request)
//            .compactMap { $0.data }
//            .decode(type: BPKAccount.self, decoder: topLevelDecoder())
//            .eraseToAnyPublisher()
//    }
}
