//
//  LoginProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 20.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork
import KeychainAccess

public typealias Token = String
private let loginUrlString = "\(baseUrlString)login/"

class LoginProcedure: GroupProcedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<TokenResponse>> = .pending
    
    let completion: (Token?, Error?) -> Void
    
    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure>
    private let _transformProcedure: TransformProcedure<Data, TokenResponse>
    
    private let email: String
    private let password: String
    
    init(username: String, password: String, completion: @escaping (Token?, Error?) -> Void) {
        
        self.email = username
        self.password = password
        
        let url = URL(string: loginUrlString + "?user_login%5Bemail%5D=\(username)&user_login%5Bpassword%5D=\(password.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        _networkProcedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, TokenResponse> {
            
//            print(try JSONSerialization.jsonObject(with: $0, options: []))
            return try JSONDecoder().decode(TokenResponse.self, from: $0)
        }
        _transformProcedure.injectPayload(fromNetwork: _networkProcedure)
        
        self.completion = completion
        
        super.init(operations: [_networkProcedure, _transformProcedure])
        
        self.add(observer: NetworkObserver(controller: NetworkActivityController(timerInterval: 1.0, indicator: UIApplication.shared)))
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        
        print(errors)
        
        if errors.isEmpty, _transformProcedure.output.success?.errors == nil {
            let keychain = Keychain()
            keychain[LoginViewController.CredentialsKey.email.rawValue] = email
            keychain[LoginViewController.CredentialsKey.password.rawValue] = password
            Server.token = _transformProcedure.output.success?.token
        }
        
        output = _transformProcedure.output
        
        completion(output.success?.token, output.success?.errors?.first?.error)
    }
}

struct TokenResponse: Codable {
    
    struct TokenError: Codable {
        let detail: String
        
        var error: NSError {
            
            return NSError(domain: "bunpro.login", code: -1, userInfo: [NSLocalizedDescriptionKey: detail])
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case token = "bunpro_api_token"
        case errors
    }
    
    let token: Token?
    let errors: [TokenError]?
}

public enum BunPuroLoginError: Error {
    case noPresentingViewControllerProvided
}

class LoggedInCondition: Condition, LoginViewControllerDelegate {
    
    private lazy var queue = ProcedureQueue()
    
    weak var presentingViewController: UIViewController?
    
    var completion: ((ConditionResult) -> Void)?
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        
        super.init()
    }
    
    override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        
        self.completion = completion
        
        if Server.token == nil {
            
            guard let presentingViewController = presentingViewController else {
                completion(ConditionResult.failure(BunPuroLoginError.noPresentingViewControllerProvided))
                return
            }
            
            let keychain = Keychain()
                        
            if let username = keychain[LoginViewController.CredentialsKey.email.rawValue],
                let password = keychain[LoginViewController.CredentialsKey.password.rawValue] {
                
                let loginProcedure = LoginProcedure(username: username, password: password) { (token, error) in
                    
                    if error == nil {
                        completion(.success(true))
                    } else {
                        completion(.failure(error!))
                    }
                }
                
                queue.add(operation: loginProcedure)
                
            } else {
                
                DispatchQueue.main.async {
                    let controller = LoginViewController(nibName: String(describing: LoginViewController.self), bundle: Bundle(for: LoginViewController.self))
                    controller.delegate = self
                    
                    controller.modalPresentationStyle = .formSheet
                    
                    presentingViewController.present(controller, animated: true, completion: nil)
                }
            }
        } else {
            completion(.success(true))
        }
    }
    
    func loginViewControllerDidLogin(_ controller: LoginViewController) {
        presentingViewController?.dismiss(animated: true, completion: nil)
        completion?(.success(true))
    }
}
