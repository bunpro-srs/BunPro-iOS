//
//  Created by Andreas Braun on 01.12.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation
import UIKit

protocol TrailingSwipeActionsConfigurationProvider {
    func swipeActionsConfiguration(for grammar: Grammar) -> UISwipeActionsConfiguration?
}

extension TrailingSwipeActionsConfigurationProvider {
    func swipeActionsConfiguration(for grammar: Grammar) -> UISwipeActionsConfiguration? {
        guard AppDelegate.isContentAccessable else { return nil }

        let review = grammar.review
        let hasReview = review?.complete ?? false

        var actions = [UIContextualAction]()

        if hasReview {
            let removeReviewAction = UIContextualAction(style: .normal, title: L10n.Review.Edit.Remove.short) { _, _, completion in
                AppDelegate.modifyReview(.remove(review!.identifier))
                completion(true)
            }

            removeReviewAction.backgroundColor = .red

            let resetReviewAction = UIContextualAction(style: .normal, title: L10n.Review.Edit.Reset.short) { _, _, completion in
                AppDelegate.modifyReview(.reset(review!.identifier))
                completion(true)
            }

            resetReviewAction.backgroundColor = .purple

            actions.append(removeReviewAction)
            actions.append(resetReviewAction)
        } else {
            let addToReviewAction = UIContextualAction(
                style: UIContextualAction.Style.normal,
                title: L10n.Review.Edit.Add.short
            ) { _, _, completion in
                AppDelegate.modifyReview(.add(grammar.identifier))
                completion(true)
            }

            actions.append(addToReviewAction)
        }

        return UISwipeActionsConfiguration(actions: actions)
    }
}
