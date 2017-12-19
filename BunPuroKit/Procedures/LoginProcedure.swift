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
    
    var output: Pending<ProcedureResult<Token>> = .pending
    
    let completion: (Token?, Error?) -> Void
    
    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>
    private let _transformProcedure: TransformProcedure<Data, Token>
    
    private let email: String
    private let password: String
    
    init(username: String, password: String, completion: @escaping (Token?, Error?) -> Void) {
        
        self.email = username
        self.password = password
        
        var components = URLComponents(string: loginUrlString)!
        
        components.queryItems = [
            URLQueryItem(name: "user_login[email]", value: username),
            URLQueryItem(name: "user_login[password]", value: password)
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        _networkProcedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, Token> {
            print(try! JSONSerialization.jsonObject(with: $0, options: []))
            return try JSONDecoder().decode(TokenResponse.self, from: $0).token }
        _transformProcedure.injectPayload(fromNetwork: _networkProcedure)
        
        self.completion = completion
        
        super.init(operations: [_networkProcedure, _transformProcedure])
        
        self.add(observer: NetworkObserver(controller: NetworkActivityController(timerInterval: 1.0, indicator: UIApplication.shared)))
    }
    
    override func procedureDidFinish(withErrors: [Error]) {
        
        print(errors)
        
        if errors.isEmpty {
            let keychain = Keychain()
            keychain[LoginViewController.CredentialsKey.email.rawValue] = email
            keychain[LoginViewController.CredentialsKey.password.rawValue] = password
            Server.token = _transformProcedure.output.value?.value
        }
        
        output = _transformProcedure.output
        
        completion(output.value?.value, output.error)
    }
}

fileprivate struct TokenResponse: Codable {
    
    enum CodingKeys: String, CodingKey {
        case token = "bunpro_api_token"
    }
    
    let token: String
}

public enum BunPuroLoginError: Error {
    case noPresentingViewControllerProvided
}

class LoggedInCondition: Condition, LoginViewControllerDelegate {
    
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
            
            DispatchQueue.main.async {
                let controller = LoginViewController(nibName: String(describing: LoginViewController.self), bundle: Bundle(for: LoginViewController.self))
                controller.delegate = self
                
                presentingViewController.present(controller, animated: true, completion: nil)
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
