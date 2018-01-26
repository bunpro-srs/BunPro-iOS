//
//  StructureInfoCell.swift
//  BunPuro
//
//  Created by Andreas Braun on 23.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

class StructureInfoCell: UITableViewCell {

    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet private weak var structureContentView: UIView! {
        didSet {
            structureContentView.layer.borderColor = UIColor.lightGray.cgColor
            structureContentView.layer.borderWidth = 1.0
            structureContentView.layer.cornerRadius = 9.0
        }
    }
}
