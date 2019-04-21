//
//  Created by Andreas Braun on 23.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import KeychainAccess
import ProcedureKit
import SafariServices
import UIKit

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

    private var failedAttempts: Int = 0
    private var failedAttemptErrors: [Error] = []

    weak var delegate: LoginViewControllerDelegate?

    private let keychain = Keychain()

    override func viewDidLoad() {
        super.viewDidLoad()

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

        let loginProcedure = LoginProcedure(username: email, password: password) { _, error in
            guard error == nil else { DispatchQueue.main.async { self.displayTokenError(error) }; return }

            DispatchQueue.main.async {
                self.activateUI()
            }

            self.delegate?.loginViewControllerDidLogin(self)
        }

        NetworkHandler.shared.queue.addOperation(loginProcedure)
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

    @IBAction private func loginButtonPressed(_ sender: UIButton) {
        validateCredentials()
    }

    @IBAction private func showPrivacy() {
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

        default:
            break
        }

        return true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
