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

public class ReviewViewControllerProcedure: Procedure, ReviewViewControllerDelegate {
    
    public let presentingViewController: UIViewController
    public let reviewMode: Bool
    
    public init(presentingViewController: UIViewController, reviewMode: Bool = true) {
        
        self.presentingViewController = presentingViewController
        self.reviewMode = reviewMode
        
        super.init()
        
        add(condition: LoggedInCondition(presentingViewController: presentingViewController))
    }
    
    public override func execute() {
        
        guard !isCancelled else { return }
        
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: ReviewViewControllerProcedure.self))
            
            let controller = storyboard.instantiateViewController(withIdentifier: "NavigationReviewViewControllerProcedure") as! UINavigationController
            (controller.visibleViewController as? ReviewViewController)?.delegate = self
            (controller.visibleViewController as? ReviewViewController)?.reviewMode = self.reviewMode
            
            controller.modalPresentationStyle = .pageSheet
            
            self.presentingViewController.present(controller, animated: true, completion: nil)
        }
    }
    
    func reviewViewControllerDidFinish(_ controller: ReviewViewController) {
        
        presentingViewController.dismiss(animated: true) {
            self.finish()
        }
    }
}
