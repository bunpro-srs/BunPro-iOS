//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import Foundation
import ProcedureKit


public final class StatusProcedure: GroupProcedure, OutputProcedure {
    public var output: Pending<ProcedureResult<(BPKAccount?, [BPKReview]?)>> = .pending

    public let completion: ((Result<(BPKAccount, [BPKReview]), Error>) -> Void)?
    public var indicator: NetworkActivityIndicatorProtocol? {
        didSet {
            guard let indicator = indicator else { return }
            addObserver(NetworkObserver(controller: NetworkActivityController(timerInterval: 1.0, indicator: indicator)))
        }
    }

    private let _userNetworkProcedure: UserProcedure
    private let _reviewsNetworkProcedure: ReviewsProcedure

    public init(presentingViewController: UIViewController, completion: ((Result<(BPKAccount, [BPKReview]), Error>) -> Void)? = nil) {
        _userNetworkProcedure = UserProcedure(presentingViewController: presentingViewController)
        _reviewsNetworkProcedure = ReviewsProcedure(presentingViewController: presentingViewController)
        _reviewsNetworkProcedure.addDependency(_userNetworkProcedure)
        self.completion = completion

        super.init(operations: [_userNetworkProcedure, _reviewsNetworkProcedure])

        addCondition(LoggedInCondition(presentingViewController: presentingViewController))
    }
    
    public override func procedureWillFinish(with error: Error?) {
        
        guard error == nil else {
            output = Pending.ready(ProcedureResult.failure(error ?? ServerError.unknown))
            return
        }

        let user = _userNetworkProcedure.output.value?.value
        let reviews = _reviewsNetworkProcedure.output.value?.value

        defer {
            if let decodingError = error as? Swift.DecodingError {
                switch decodingError {
                case .typeMismatch, .valueNotFound:
                    logger.info("Server changed something!")

                case .keyNotFound:
                    logger.info("Login token changed")
                    Server.reset()

                case .dataCorrupted:
                    break // NOTE: Seems to be a bug in swift...

                @unknown default:
                    break
                }
            }
        }

        output = Pending.ready(ProcedureResult.success((user, reviews)))
    }
    
    public override func procedureDidFinish(with error: Error?) {
        if let error = output.error {
            completion?(.failure(error))
        } else if let account = output.value?.value?.0, let reviews = output.value?.value?.1 {
            completion?(.success((account, reviews)))
        }
    }
}
