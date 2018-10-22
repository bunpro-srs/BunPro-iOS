//
//  BasicInfoCell.swift
//  BunPuro
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
        
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
}
