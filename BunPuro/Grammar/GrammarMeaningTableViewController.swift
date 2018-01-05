//
//  GrammarMeaningTableViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 21.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import BunPuroKit

class GrammarMeaningViewController: UIViewController, GrammarPresenter {

    @IBOutlet private weak var titleLable: UILabel!
    @IBOutlet private weak var meaningLabel: UILabel!
    @IBOutlet private weak var cautionLabel: UILabel!
    @IBOutlet private weak var structureLabel: UILabel!
    
    @IBOutlet private weak var structureContentView: UIView! {
        didSet {
            structureContentView.layer.borderColor = UIColor.lightGray.cgColor
            structureContentView.layer.borderWidth = 1.0
            structureContentView.layer.cornerRadius = 9.0
        }
    }
    
    var grammar: Grammar?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(grammar != nil)
        
        titleLable.numberOfLines = 0
        titleLable.textAlignment = .center
        
        meaningLabel.numberOfLines = 0
        meaningLabel.textAlignment = .center
        
        cautionLabel.numberOfLines = 0
        cautionLabel.textAlignment = .center
        
        structureLabel.numberOfLines = 0
        structureLabel.textAlignment = .center
        
        titleLable.text = grammar?.title
        meaningLabel.text = grammar?.meaning
        
        if let caution = grammar?.caution, !caution.isEmpty {
            cautionLabel.text = "⚠️ \(caution)"
        } else {
            cautionLabel.text = nil
            cautionLabel.isEnabled = true
        }
        
        structureLabel.text = grammar?.structure?.replacingOccurrences(of: ", ", with: "\n")
    }
}


