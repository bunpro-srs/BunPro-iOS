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

public class ReviewsProcedure: BunPuroProcedure<ReviewResponse> {
    
    let collection: ReviewCollection
    
    override var hasMilliseconds: Bool { return true }
    override var url: URL { return URL(string: "\(baseUrlString)/\(collection.rawValue)")! }
    
    init(presentingViewController: UIViewController, collection: ReviewCollection = .all, completion: ((ReviewResponse?, Error?) -> Void)? = nil) {
        
        self.collection = collection
        
        super.init(presentingViewController: presentingViewController, completion: completion)
    }
}
