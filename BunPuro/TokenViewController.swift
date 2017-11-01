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
            
            Server.updatedStatus(completion: { (userResponse, userProgress, reviews, error) in
                guard let userResponse = userResponse,
                    let userProgress = userProgress,
                    let reviews = reviews else {
                        DispatchQueue.main.async {
                            self.displayTokenError()
                        }
                        return
                }
                
                Keychain()[KeychainAccessKey] = token
                
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: SegueIdentifier.presentTabBarController, sender: (userResponse, userProgress, reviews))
                }
            })
            
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
            
            guard let (userResponse, progessResponse, reviewResponse) = sender as? (UserResponse, UserProgress, ReviewResponse) else {
                fatalError("No data provided.")
            }
            
            let tabBarController = segue.destination as? UITabBarController
            let statusViewController = tabBarController?.viewControllers?.first?.content as? StatusTableViewController
            
            statusViewController?.userResponse = userResponse
            statusViewController?.progressResponse = progessResponse
            statusViewController?.reviewResponse = reviewResponse
        }
    }

}
