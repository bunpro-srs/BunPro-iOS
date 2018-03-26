//
//  HimitsuTableViewCell.swift
//  BunPuro
//
//  Created by Andreas Braun on 26.03.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

class HimitsuTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet private weak var cloakView: UIVisualEffectView!
    
    var isCloaked: Bool = true {
        didSet {
            cloakView.isHidden = isCloaked
        }
    }

}
