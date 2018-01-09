//
//  ErrorViewController.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 09.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

class ErrorViewController: UIViewController {
    
    @IBOutlet weak private var textView: UITextView!
    
    var errors: [Error]?

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.text = errors?.map({ String(describing: $0) }).joined(separator: "\n")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
    }
    
    @IBAction private func close() {
        presentingViewController?.dismiss(animated: true)
    }
}
