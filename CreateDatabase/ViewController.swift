//
//  ViewController.swift
//  CreateDatabase
//
//  Created by Andreas Braun on 26.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit
import CoreData
import BunPuroKit

class ViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(NSPersistentContainer.defaultDirectoryURL())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func importButtonPressed(_ sender: UIButton) {
        
        activityIndicator.startAnimating()
        
        let updateProcedure = UpdateGrammarProcedure(presentingViewController: self)
        
        updateProcedure.completionBlock = {
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
        }
        
        Server.add(procedure: updateProcedure)
    }
    
}

