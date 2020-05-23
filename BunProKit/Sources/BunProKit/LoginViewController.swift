//
//  File.swift
//  
//
//  Created by Andreas Braun on 20.07.19.
//

import Foundation
import KeychainAccess
import UIKit

protocol LoginViewControllerDelegate: class {
    func loginViewControllerDidLogin(_ controller: LoginViewController)
}

final class LoginViewController: UITableViewController {
    
    enum CredentialsKey: String {
        case email
        case password
        case token
    }
    
    weak var delegate: LoginViewControllerDelegate?
    
    private let keychain = Keychain()
    
    
    private let buttonCellIndexPathSection = 1
    private let textCellIndexPathSection = 0
    
    override init(style: UITableView.Style) {
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: TextFieldCell.cellIdentifier)
        tableView.register(ButtonCell.self, forCellReuseIdentifier: ButtonCell.cellIdentifier)
        
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = true
    }
        
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case textCellIndexPathSection:
            return 2
        case buttonCellIndexPathSection:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case textCellIndexPathSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldCell.cellIdentifier, for: indexPath) as! TextFieldCell
            
            switch indexPath.row {
            case 0:
                cell.textContentType = .emailAddress
                cell.title = keychain[string: CredentialsKey.email.rawValue]
            case 1:
                cell.textContentType = .password
                cell.title = keychain[string: CredentialsKey.password.rawValue]
            default:
                fatalError("No such cell")
            }
            
            cell.textDidChange = textDidChange(cell:)
            
            cell.selectionStyle = .none
            
            return cell
        case buttonCellIndexPathSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: ButtonCell.cellIdentifier, for: indexPath) as! ButtonCell
            
            cell.title = "Login"
            
            cell.isEnabled = validateCredentials()
            
            return cell
        default:
            fatalError("No such section")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == buttonCellIndexPathSection && buttonCell?.isEnabled == true{
                login()
        }
        
    }
    
    private var emailTextFieldCell: TextFieldCell? {
        return (tableView.cellForRow(at: IndexPath(row: 0, section: textCellIndexPathSection)) as? TextFieldCell)
    }
    
    private var passwordTextFieldCell: TextFieldCell? {
        return (tableView.cellForRow(at: IndexPath(row: 1, section: textCellIndexPathSection)) as? TextFieldCell)
    }
    
    private var buttonCell: ButtonCell? {
        return (tableView.cellForRow(at: IndexPath(row: 0, section: buttonCellIndexPathSection)) as? ButtonCell)
    }
    
    private func textDidChange(cell: TextFieldCell) {
        buttonCell?.isEnabled = validateCredentials()
    }
    
    private func validateEmail(_ candidate: String) -> Bool {
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let isValid = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
        emailTextFieldCell?.isInputValid = isValid
        
        return isValid
    }
    
    private func validateCredentials() -> Bool {
        guard let email = emailTextFieldCell?.title else { return false }
        guard let password = passwordTextFieldCell?.title else { return false }
        
        return !password.isEmpty && validateEmail(email)
    }
    
    private func login() {

        guard let email = emailTextFieldCell?.title, !email.isEmpty else { return }
        guard let password = passwordTextFieldCell?.title, !password.isEmpty else { return }
        
        updateUI(enabled: false)
        
        let loginProcedure = LoginProcedure(username: email, password: password) { _, error in
            guard error == nil else { DispatchQueue.main.async {
                self.updateUI(enabled: true)
                self.showLoginError(error!)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.updateUI(enabled: true)
            }
            
            //We should only store login credentials if we logged in successfully
            self.keychain[string: CredentialsKey.email.rawValue] = email
            self.keychain[string: CredentialsKey.password.rawValue] = password
            
            self.delegate?.loginViewControllerDidLogin(self)
        }
        
        NetworkHandler.shared.queue.addOperation(loginProcedure)
    }

    private func updateUI(enabled: Bool) {
        emailTextFieldCell?.isEnabled = enabled
        passwordTextFieldCell?.isEnabled = enabled
        buttonCell?.isEnabled = enabled
    }
    
    private func showLoginError(_ error: Error) {
        let alert = UIAlertController(title: "Login", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
        self.present(alert, animated: true)
    }
}

private protocol CellIdentifiable: class { }

extension CellIdentifiable {
    static var cellIdentifier: String { String(describing: Self.self) }
}

final private class TextFieldCell: UITableViewCell, CellIdentifiable {
    
    enum Style {
        case Default
        case Invalid
    }

    var title: String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    private var textfieldStyle: TextFieldCell.Style = .Default {
        didSet {
            if textfieldStyle == .Default {
                textField.textColor = .darkText
            } else {
                textField.textColor = .systemRed
            }
        }
    }
    
    var isInputValid: Bool = true {
        didSet {
            textfieldStyle = isInputValid == true ? .Default : .Invalid
        }
    }
        
    var textContentType: UITextContentType {
        get { textField.textContentType }
        set {
            textField.textContentType = newValue
            
            switch newValue {
            case .emailAddress:
                placeholder = "Email Address"
                isSecureTextEntry = false
            case .password:
                placeholder = "Password"
                isSecureTextEntry = true
            default: break
            }
        }
    }
    
    var textDidChange: ((TextFieldCell) -> Void)?
    
    var isEnabled: Bool {
        get { textField.isEnabled }
        set { textField.isEnabled = newValue }
    }
    
    private var textField: UITextField
    
    private var placeholder: String? {
        get { textField.placeholder }
        set { textField.placeholder = newValue }
    }
    
    private var isSecureTextEntry: Bool {
        get { textField.isSecureTextEntry }
        set { textField.isSecureTextEntry = newValue }
    }
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        self.textField = UITextField()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.textField.borderStyle = .roundedRect
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(self.textField)
        
        NSLayoutConstraint.activate([
            self.textField.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1),
            bottomAnchor.constraint(equalToSystemSpacingBelow: self.textField.bottomAnchor, multiplier: 1),
            self.textField.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1),
            trailingAnchor.constraint(equalToSystemSpacingAfter: self.textField.trailingAnchor, multiplier: 1)
        ])
        
        self.textField.addTarget(self, action: #selector(textFieldDidChangeValue(_:)), for: .editingChanged)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func textFieldDidChangeValue(_ textField: UITextField) {
        textDidChange?(self)
    }
}

final private class ButtonCell: UITableViewCell, CellIdentifiable {

    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }
    
    var isEnabled: Bool {
        get { selectionStyle == .default }
        set {
            selectionStyle = newValue ? .default : .none
            label.textColor = newValue ? tintColor : .lightGray
        }
    }
    
    private var label: UILabel
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        self.label = UILabel()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.label.textAlignment = .center
        self.label.textColor = tintColor
        self.label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(self.label)
        
        NSLayoutConstraint.activate([
            self.label.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1.5),
            bottomAnchor.constraint(equalToSystemSpacingBelow: self.label.bottomAnchor, multiplier: 1.5),
            self.label.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1),
            trailingAnchor.constraint(equalToSystemSpacingAfter: self.label.trailingAnchor, multiplier: 1)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
