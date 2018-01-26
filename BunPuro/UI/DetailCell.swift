//
//  RightDetailCell.swift
//  BunPuro
//
//  Created by Andreas Braun on 15.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit

class DetailCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel! {
        didSet {
            nameLabel.numberOfLines = 0
        }
    }
    
    @IBOutlet weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.numberOfLines = 0
        }
    }
    
    @IBOutlet private weak var progressView: UIProgressView! {
        didSet {
            progressView?.progress = 0.0
        }
    }
    
    func setProgress(_ progress: Float, animated: Bool) {
        
        progressView?.setProgress(progress, animated: animated)
    }
    
}
