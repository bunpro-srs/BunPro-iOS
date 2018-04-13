//
//  JLPTProgressTableViewCell.swift
//  BunPuro
//
//  Created by Andreas Braun on 06.04.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

class JLPTProgressTableViewCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet private var progressView: UIProgressView! { didSet { progressView.subviews.forEach { $0.layer.cornerRadius = 4; $0.clipsToBounds = true }} }
        
    func setProgress(_ progress: Float, animated: Bool) {
        progressView.setProgress(progress, animated: animated)
    }
}
