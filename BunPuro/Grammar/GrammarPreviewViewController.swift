//
//  Created by Andreas Braun on 01.12.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import UIKit

class GrammarPreviewViewController: UIViewController {
    @IBOutlet private weak var mainStackView: UIStackView!

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var meaningLabel: UILabel!
    @IBOutlet private weak var cautionLabel: UILabel!
    @IBOutlet private weak var structureContentView: UIView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var contentStackView: UIStackView!

    var grammar: Grammar!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.numberOfLines = 0
        meaningLabel.numberOfLines = 0
        cautionLabel.numberOfLines = 0
        descriptionLabel.numberOfLines = 0
        structureContentView.layer.cornerRadius = 12.0

        titleLabel.text = grammar.title
        meaningLabel.text = grammar.meaning

        let englishFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 12))

        if let caution = grammar?.caution?.replacingOccurrences(of: "<span class='chui'>", with: "").replacingOccurrences(of: "</span>", with: ""),
            let attributed = "⚠️ \(caution)".htmlAttributedString(font: englishFont, color: .white),
            !caution.isEmpty {
            cautionLabel.text = attributed.string
        } else {
            cautionLabel.text = nil
            cautionLabel.isHidden = true
        }

        descriptionLabel.text = grammar?
            .structure?
            .replacingOccurrences(of: ", ", with: "</br>")
            .htmlAttributedString(font: englishFont, color: .white)?
            .string

        contentStackView?.isHidden = grammar?.review?.complete == false

        let streak = grammar.review?.streak ?? 0

        for (index, hanko) in contentStackView.arrangedSubviews.enumerated() {
            hanko.tintColor = .secondaryLabel
            hanko.alpha = (index + 1) <= streak ? 1.0 : 0.2
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var size = view.bounds.size
        size.height = mainStackView.bounds.height + (mainStackView.frame.origin.y * 2)
        preferredContentSize = size
    }
}
