//
//  TokenViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 01.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import BunPuroKit
import KeychainAccess
import CoreData

private let KeychainAccessKey = "APIToken"

class TokenViewController: UIViewController, SegueHandler {
    
    enum SegueIdentifier: String {
        case presentTabBarController
    }

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        textField.text = Keychain()[string: KeychainAccessKey]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        validateToken()
    }
    
    private func validateToken() {
        
        if let token = textField.text, !token.isEmpty {
            activityIndicator.startAnimating()
            textField.isEnabled = false
            loginButton.isEnabled = false
            
            Server.apiToken = token
            
            Server.updateStatus { (error) in
                
                guard error == nil else { self.displayTokenError(); return }
                
                Keychain()[KeychainAccessKey] = token
                
                self.performSegue(withIdentifier: SegueIdentifier.presentTabBarController, sender: self)
                
                Server.updateJLPT { (jlpts, error) in
                    guard error == nil else { return }
                    guard let jlpts = jlpts else { return }
                    
                    let context = AppDelegate.coreDataStack.managedObjectContext
                    
                    context.perform {
                        jlpts.forEach { (jlpt) in
                            
                            let newJPLT = JLPT(context: context)
                            
                            newJPLT.level = Int64(jlpt.level)
                            newJPLT.name = jlpt.name
                            
                            jlpt.lessons.forEach { (lesson) in
                                
                                let newLesson = Lesson(context: context)
                                
                                newLesson.id = lesson.id
                                newLesson.order = Int64(lesson.order)
                                newLesson.jlpt = newJPLT
                                
                                lesson.grammar.forEach { (grammar) in
                                    
                                    let newGrammar = Grammar(context: context)
                                    
                                    newGrammar.id = grammar.id
                                    newGrammar.lesson = newLesson
                                    newGrammar.title = grammar.title
                                    newGrammar.meaning = grammar.meaning
                                }
                            }
                        }
                        
                        AppDelegate.coreDataStack.save()
                    }
                }
            }
            
        } else {
            activityIndicator.stopAnimating()
            textField.isEnabled = true
            loginButton.isEnabled = true
        }
    }
    
    private func displayTokenError() {
        
        activityIndicator.stopAnimating()
        textField.isEnabled = true
        loginButton.isEnabled = true
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        
        validateToken()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segueIdentifier(for: segue) {
        case .presentTabBarController:
            break // Nothing to setup
        }
    }

}
