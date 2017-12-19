//
//  ReviewViewControllerProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 19.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

public class ReviewViewControllerProcedure: Procedure {
    
    public let presentingViewController: UIViewController
    
    public init(presentingViewController: UIViewController) {
        
        self.presentingViewController = presentingViewController
        
        super.init()
        
        add(condition: LoggedInCondition(presentingViewController: presentingViewController))
    }
    
    public override func execute() {
        
        guard !isCancelled else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: ReviewViewControllerProcedure.self))

        let controller = storyboard.instantiateViewController(withIdentifier: "NavigationReviewViewControllerProcedure")
        
        presentingViewController.present(controller, animated: true, completion: nil)
    }
}
