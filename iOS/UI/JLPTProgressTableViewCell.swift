//
//  Created by Andreas Braun on 06.04.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

final class JLPTProgressTableViewCell: UITableViewCell {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var progressView: UIProgressView! { didSet { progressView.subviews.forEach { $0.layer.cornerRadius = 4; $0.clipsToBounds = true } } }

    var title: String? {
        get { titleLabel?.text }
        set { titleLabel?.text = newValue }
    }

    var subtitle: String? {
        get { subtitleLabel?.text }
        set { subtitleLabel?.text = newValue }
    }

    func setProgress(_ progress: Float, animated: Bool) {
        guard progressView.progress != progress else { return }
        progressView.setProgress(progress, animated: animated)
    }
}
