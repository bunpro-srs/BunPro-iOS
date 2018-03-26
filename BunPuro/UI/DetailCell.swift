//
//  RightDetailCell.swift
//  BunPuro
//
//  Created by Andreas Braun on 15.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit

class DetailCell: UITableViewCell {
    
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
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
    
    @IBAction func didPressCustomAction(_ sender: UIButton) {
        customAction?(self)
    }
}
