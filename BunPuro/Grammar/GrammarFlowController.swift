//
//  Created by Cihat Gündüz on 24.04.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import UIKit

class GrammarFlowController {
    func editReviewButtonPressed(grammar: Grammar, barButtonItem: UIBarButtonItem, viewController: UIViewController) {
        if grammar.review?.complete == true {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            let removeAction = UIAlertAction(title: L10n.Review.Edit.remove, style: .destructive) { _ in
                AppDelegate.modifyReview(.remove(grammar.review!.identifier))
            }

            alertController.addAction(removeAction)

            let resetAction = UIAlertAction(title: L10n.Review.Edit.reset, style: .destructive) { _ in
                AppDelegate.modifyReview(.reset(grammar.review!.identifier))
            }

            alertController.addAction(resetAction)

            alertController.addAction(
                UIAlertAction(title: L10n.General.cancel, style: .cancel, handler: nil)
            )

            alertController.popoverPresentationController?.barButtonItem = barButtonItem
            viewController.present(alertController, animated: true)
        } else {
            AppDelegate.modifyReview(.add(grammar.identifier))
        }
    }
}
