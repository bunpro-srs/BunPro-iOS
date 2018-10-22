//
//  StructureInfoCell.swift
//  BunPuro
//
//  Created by Andreas Braun on 23.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

final class StructureInfoCell: UITableViewCell {

    @IBOutlet weak var descriptionLabel: UILabel! {
        didSet {
            descriptionLabel.numberOfLines = 0
        }
    }
    
    @IBOutlet private weak var structureContentView: UIView! {
        didSet {
            structureContentView.layer.borderColor = UIColor(named: "Background")?.cgColor
            structureContentView.layer.borderWidth = 0.5
            structureContentView.layer.cornerRadius = 9.0
        }
    }
}
