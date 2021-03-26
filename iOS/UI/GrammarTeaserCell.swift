//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

final class GrammarTeaserCell: UITableViewCell {
    @IBOutlet weak var japaneseLabel: UILabel! {
        didSet {
            japaneseLabel.numberOfLines = 0
        }
    }

    @IBOutlet weak var meaningLabel: UILabel! {
        didSet {
            meaningLabel.numberOfLines = 0
        }
    }

    @IBOutlet private weak var hankoImageView: UIImageView!

    var isComplete = false {
        didSet {
            hankoImageView?.tintColor = .lightGray
            hankoImageView.isHidden = !isComplete
        }
    }

    func update(with grammar: Grammar) {
        japaneseLabel?.text = grammar.title
        meaningLabel?.text = grammar.meaning

        let hasReview = grammar.review?.complete ?? false
        isComplete = hasReview
    }
}
