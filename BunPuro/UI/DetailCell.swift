//
//  Created by Andreas Braun on 15.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit

final class DetailCell: UITableViewCell {
    var longPressGestureRecognizer: UILongPressGestureRecognizer?

    @IBOutlet private weak var nameLabel: UILabel! {
        didSet {
            nameLabel.numberOfLines = 0
        }
    }

    @IBOutlet private weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.numberOfLines = 0
        }
    }

    @IBOutlet private weak var progressView: UIProgressView! {
        didSet {
            progressView?.progress = 0.0
        }
    }

    var name: String? {
        get {
            return nameLabel?.text
        }
        set {
            nameLabel?.text = newValue
        }
    }

    var attributedName: NSAttributedString? {
        get {
            return nameLabel?.attributedText
        }
        set {
            nameLabel?.attributedText = newValue
        }
    }

    var nameColor: UIColor? {
        get {
            return nameLabel?.textColor
        }
        set {
            nameLabel?.textColor = newValue
        }
    }

    var descriptionText: String? {
        get {
            return descriptionLabel?.text
        }
        set {
            descriptionLabel?.text = newValue
        }
    }

    var attributedDescriptionText: NSAttributedString? {
        get {
            return descriptionLabel?.attributedText
        }
        set {
            descriptionLabel?.attributedText = newValue
        }
    }

    var isDescriptionLabelHidden: Bool {
        get {
            return descriptionLabel?.isHidden ?? false
        }
        set {
            descriptionLabel?.isHidden = newValue
        }
    }

    var actionImage: UIImage? {
        didSet {
            actionButton?.setImage(actionImage, for: .normal)
            actionButton?.isHidden = actionImage == nil
        }
    }

    @IBOutlet private weak var actionButton: UIButton!

    var customAction: ((DetailCell) -> Void)?

    func setProgress(_ progress: Float, animated: Bool) {
        progressView?.setProgress(progress, animated: animated)
    }

    @IBAction private func didPressCustomAction(_ sender: UIButton) {
        customAction?(self)
    }
}
