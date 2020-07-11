//
//  Created by Andreas Braun on 23.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

final class BasicInfoCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.numberOfLines = 0
        }
    }

    @IBOutlet weak var meaningLabel: UILabel! {
        didSet {
            meaningLabel.numberOfLines = 0
        }
    }

    @IBOutlet weak var cautionLabel: UILabel! {
        didSet {
            cautionLabel.numberOfLines = 0
        }
    }

    @IBOutlet private weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.numberOfLines = 0
        }
    }

    var attributedDescription: String? {
        get {
            descriptionLabel?.text
        }
        set {
            descriptionLabel.text = newValue
        }
    }

    @IBOutlet private weak var structureContentView: UIView! {
        didSet {
            structureContentView.layer.cornerRadius = 9.0
        }
    }

    @IBOutlet weak var contentStackView: UIStackView!

    var streak: Int = 0

    override func layoutSubviews() {
        for (index, hanko) in contentStackView.arrangedSubviews.enumerated() {
            hanko.tintColor = .secondaryLabel
            hanko.alpha = (index + 1) <= streak ? 1.0 : 0.2
        }

        super.layoutSubviews()
    }

    override var canBecomeFirstResponder: Bool {
        true
    }
}
