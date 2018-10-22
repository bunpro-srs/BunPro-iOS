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
        case .all: return "all_reviews_total"
        case .current: return "current_reviews"
        }
    }
}

private struct _ReviewContainer: Codable {
    let reviews: [BPKReview]
    let ghost_reviews: [BPKReview]
    let self_study_reviews: [BPKReview]
}

private final class _ReviewsProcedure: BunPuroProcedure<_ReviewContainer> {
    
    let collection: ReviewCollection
    
    override var hasMilliseconds: Bool { return true }
    override var url: URL { return URL(string: "\(baseUrlString)reviews/\(collection.rawValue)")! }
    
    init(presentingViewController: UIViewController, collection: ReviewCollection = .all, completion: ((_ReviewContainer?, Error?) -> Void)? = nil) {
        
        self.collection = collection
        
        super.init(presentingViewController: presentingViewController, completion: completion)
    }
}

public final class ReviewsProcedure: GroupProcedure, OutputProcedure {
    
    public var output: Pending<ProcedureResult<[BPKReview]>> {
        get { return transformProcedure.output }
        set { assertionFailure("\(#function) should never be called.") }
    }
    
    public let completion: (([BPKReview]?, Error?) -> Void)?
    
    private let downloadProcedure: _ReviewsProcedure?
    private let transformProcedure: TransformProcedure<_ReviewContainer, [BPKReview]>
    
    public init(presentingViewController: UIViewController, completion: (([BPKReview]?, Error?) -> Void)? = nil) {
        
        self.completion = completion
        
        downloadProcedure = _ReviewsProcedure(presentingViewController: presentingViewController)
        transformProcedure = TransformProcedure<_ReviewContainer, [BPKReview]> { $0.reviews + $0.ghost_reviews + $0.self_study_reviews }
        transformProcedure.injectResult(from: downloadProcedure!)
        
        super.init(operations: [downloadProcedure!, transformProcedure])
    }
}
