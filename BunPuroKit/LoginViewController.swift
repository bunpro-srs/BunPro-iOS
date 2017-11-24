//
//  LoginViewController.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 23.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import KeychainAccess
import ProcedureKit
import LocalAuthentication

protocol LoginViewControllerDelegate: class {
    func loginViewControllerDidLogin(_ controller: LoginViewController)
}

class LoginViewController: UIViewController {
    
    private enum CredentialsKey: String {
        case email
        case password
        case token
    }
    
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    
    @IBOutlet private weak var loginButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    weak var delegate: LoginViewControllerDelegate?
    
    private let keychain = Keychain()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.text = keychain[string: CredentialsKey.email.rawValue]
        passwordTextField.text = keychain[string: CredentialsKey.password.rawValue]
        
        validateCredentials()
    }
    
    private func validateCredentials() {
        guard let email = emailTextField.text, !email.isEmpty else { return }
        guard let password = passwordTextField.text, !password.isEmpty else { return }
        
        UIView.animate(withDuration: 0.25) {
            self.activityIndicator.startAnimating()
        }
        emailTextField.isEnabled = false
        passwordTextField.isEnabled = false
        loginButton.isEnabled = false
        
        let loginProcedure = LoginProcedure(username: email, password: password) { (token, error) in
            guard error == nil else { DispatchQueue.main.async { self.displayTokenError() }; return }
            
            self.keychain[CredentialsKey.email.rawValue] = email
            self.keychain[CredentialsKey.password.rawValue] = password
            
            DispatchQueue.main.async {
                self.activateUI()
            }
            
            Server.token = token
            
            self.delegate?.loginViewControllerDidLogin(self)
        }
        
        NetworkHandler.shared.queue.add(operation: loginProcedure)
    }
    
    private func displayTokenError() {
        
        activateUI()
    }
    
    private func activateUI() {
        
        UIView.animate(withDuration: 0.25) {
            self.activityIndicator.stopAnimating()
        }
        
        emailTextField.isEnabled = true
        passwordTextField.isEnabled = true
        loginButton.isEnabled = true
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        
        validateCredentials()
    }

}
