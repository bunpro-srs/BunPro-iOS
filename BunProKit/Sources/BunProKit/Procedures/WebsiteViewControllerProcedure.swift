//
//  Created by Andreas Braun on 19.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import Foundation
import ProcedureKit

public final class WebsiteViewControllerProcedure: Procedure, ReviewViewControllerDelegate {
    public let presentingViewController: UIViewController
    public let website: Website
    public var userActivity: NSUserActivity?

    public init(presentingViewController: UIViewController, website: Website = .review) {
        self.presentingViewController = presentingViewController
        self.website = website

        super.init()

        addCondition(LoggedInCondition(presentingViewController: presentingViewController))
    }

    override public func execute() {
        guard !isCancelled else { return }

        DispatchQueue.main.async {
            let controller = ReviewViewController()
            controller.delegate = self
            controller.website = self.website

            let navigationController = UINavigationController(rootViewController: controller)
            navigationController.modalPresentationStyle = .fullScreen

            self.presentingViewController.present(navigationController, animated: true) {
                controller.userActivity = self.userActivity
            }
        }
    }

    func reviewViewControllerDidFinish(_ controller: ReviewViewController) {
        presentingViewController.dismiss(animated: true) {
            self.finish()
        }
    }
}
