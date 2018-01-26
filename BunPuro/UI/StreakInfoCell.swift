//
//  StreakInfoCell.swift
//  BunPuro
//
//  Created by Andreas Braun on 23.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

class StreakInfoCell: UITableViewCell {
    
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private var hankoCollection: [UIImageView]!
    
    var streak: Int = 0
    
    override func layoutSubviews() {
        
        for (index, hanko) in hankoCollection.enumerated() {
            
            hanko.tintColor = (index + 1) < streak ? .red : #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1)
        }
        
        super.layoutSubviews()
    }
}
