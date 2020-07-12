//
//  Created by Cihat Gündüz on 24.04.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import UIKit

class GrammarFlowController {
    func editReviewButtonPressed(grammar: Grammar, barButtonItem: UIBarButtonItem, viewController: UIViewController) {
        let complete = grammar.review?.complete == true

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let addAction = UIAlertAction(title: L10n.Review.Edit.add, style: .default) { _ in
            AppDelegate.modifyReview(.add(grammar.identifier))
        }

        addAction.isEnabled = !complete

        alertController.addAction(addAction)

        let resetAction = UIAlertAction(title: L10n.Review.Edit.reset, style: .destructive) { _ in
            AppDelegate.modifyReview(.reset(grammar.review!.identifier))
        }

        resetAction.isEnabled = complete

        alertController.addAction(resetAction)

        let removeAction = UIAlertAction(title: L10n.Review.Edit.remove, style: .destructive) { _ in
            AppDelegate.modifyReview(.remove(grammar.review!.identifier))
        }

        removeAction.isEnabled = complete

        alertController.addAction(removeAction)

        alertController.addAction(
            UIAlertAction(title: L10n.General.cancel, style: .cancel, handler: nil)
        )

        alertController.popoverPresentationController?.barButtonItem = barButtonItem
        viewController.present(alertController, animated: true)
    }
}
