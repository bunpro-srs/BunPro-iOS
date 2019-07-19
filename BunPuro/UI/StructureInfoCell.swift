//
//  Created by Andreas Braun on 23.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

final class StructureInfoCell: UITableViewCell {
    @IBOutlet private weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.numberOfLines = 0
        }
    }

    var attributedDescription: String? {
        get {
            return descriptionLabel?.text
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
}
