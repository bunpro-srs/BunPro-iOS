//
//  Created by Andreas Braun on 01.12.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation
import UIKit

extension SearchTableViewController {
    func contextMenuConfiguration(for grammar: Grammar) -> UIContextMenuConfiguration? {
        guard AppDelegate.isContentAccessable else { return nil }

        let review = grammar.review
        let hasReview = review?.complete ?? false

        var reviewActions: [UIAction] = []
        var meaningActions: [UIAction] = []

        if hasReview {
            reviewActions.append(
                UIAction(title: L10n.Review.Edit.Remove.short, image: .trashFill, attributes: .destructive) { _ in
                    AppDelegate.modifyReview(.remove(review!.identifier))
                }
            )

            reviewActions.append(
                UIAction(title: L10n.Review.Edit.Reset.short, image: .repeatOne, attributes: .destructive) { _ in
                    AppDelegate.modifyReview(.reset(review!.identifier))
                }
            )
        } else {
            reviewActions.append(
                UIAction(title: L10n.Review.Edit.Add.short, image: .repeat) { _ in
                    AppDelegate.modifyReview(.add(grammar.identifier))
                }
            )
        }

        meaningActions.append(
            UIAction(title: L10n.Copy.japanese, image: .docOnDocFill) { _ in
                UIPasteboard.general.string = grammar.title
            }
        )
        meaningActions.append(
            UIAction(title: L10n.Copy.meaning, image: .docOnDocFill) { _ in
                UIPasteboard.general.string = grammar.meaning
            }
        )

        let reviewMenu = UIMenu(title: "Review", options: .displayInline, children: reviewActions)
        let meaningMenu = UIMenu(title: "Content", options: .displayInline, children: meaningActions)

        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: {
                let grammarViewCtrl = StoryboardScene.GrammarDetail.grammarPreviewViewController.instantiate()
                grammarViewCtrl.grammar = grammar

                return grammarViewCtrl
            }, actionProvider: { _ in
                UIMenu(title: "Review", children: [reviewMenu, meaningMenu])
            }
        )
    }
}
