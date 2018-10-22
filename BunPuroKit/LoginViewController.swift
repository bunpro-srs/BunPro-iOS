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
import PasswordManager
import SafariServices

protocol LoginViewControllerDelegate: class {
    func loginViewControllerDidLogin(_ controller: LoginViewController)
}

final class LoginViewController: UIViewController, UITextFieldDelegate {
    
    enum CredentialsKey: String {
        case email
        case password
        case token
    }
    
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    
    @IBOutlet private weak var loginButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var onePasswordButton: UIButton!
    
    private var failedAttempts: Int = 0
    private var failedAttemptErrors: [Error] = []
    
    weak var delegate: LoginViewControllerDelegate?
    
    private let keychain = Keychain()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onePasswordButton.isHidden = !PasswordExtension.shared.isAvailable()
        
        emailTextField.text = keychain[string: CredentialsKey.email.rawValue]
        passwordTextField.text = keychain[string: CredentialsKey.password.rawValue]
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
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
            guard error == nil else { DispatchQueue.main.async { self.displayTokenError(error) }; return }
            
            DispatchQueue.main.async {
                self.activateUI()
            }
            
            self.delegate?.loginViewControllerDidLogin(self)
        }
        
        NetworkHandler.shared.queue.add(operation: loginProcedure)
    }
    
    private func displayTokenError(_ error: Error?) {
        
        failedAttempts += 1
        
        if let error = error, failedAttempts == 3 {
            failedAttemptErrors.append(error)
        }
        
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
    
    @IBAction func showOnePasswordExtension(_ sender: UIButton) {
        
        PasswordExtension.shared.findLoginDict(for: websiteUrlString, viewController: self, sender: sender) { (loginDictionary, error) in
            
            guard let loginDictionary = loginDictionary else {
                return
            }
            
            if loginDictionary.isEmpty {
                print(error ?? "")
            }
            
            self.emailTextField.text = loginDictionary[PELogin.username.key()] as? String
            self.passwordTextField.text = loginDictionary[PELogin.password.key()] as? String
        }
    }
    
    @IBAction func showPrivacy() {
        
        guard let url = URL(string: "https://bunpro.jp/privacy") else { return }
        
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true
        
        let safariViewController = SFSafariViewController(url: url, configuration: configuration)
        
        safariViewController.preferredBarTintColor = .black
        safariViewController.preferredControlTintColor = UIColor(named: "Main Tint")
        
        present(safariViewController, animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField {
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            loginButtonPressed(loginButton)
        default: break
        }
        
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
