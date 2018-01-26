//
//  GrammarTeaserCell.swift
//  BunPuro
//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

class GrammarTeaserCell: UITableViewCell {

    @IBOutlet weak var japaneseLabel: UILabel!
    @IBOutlet weak var meaningLabel: UILabel!
    
    @IBOutlet private weak var hankoImageView: UIImageView!
    
    var isComplete: Bool = false {
        didSet {
            
            hankoImageView?.tintColor = isComplete ? .red : #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1)
        }
    }
}
