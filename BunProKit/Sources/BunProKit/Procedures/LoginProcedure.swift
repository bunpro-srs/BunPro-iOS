//
//  Created by Andreas Braun on 20.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import Foundation
import KeychainAccess
import ProcedureKit
import ProcedureKitNetwork


public typealias Token = String
private let loginUrlString = "\(baseUrlString)login/"

class LoginProcedure: GroupProcedure, OutputProcedure {
    var output: Pending<ProcedureResult<TokenResponse>> = .pending

    let completion: (Token?, Error?) -> Void

    private let _networkProcedure: NetworkProcedure<NetworkDataProcedure>
    private let _transformProcedure: TransformProcedure<Data, TokenResponse>

    private let email: String
    private let password: String

    deinit {
        print("\(self) deinit")
    }
    
    init(username: String, password: String, completion: @escaping (Token?, Error?) -> Void) {
        self.email = username
        self.password = password

        let percentEscapedPassword: String = password.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let url = URL(string: loginUrlString + "?user_login%5Bemail%5D=\(username)&user_login%5Bpassword%5D=\(percentEscapedPassword)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        _networkProcedure = NetworkProcedure { NetworkDataProcedure(session: URLSession.shared, request: request) }
        _transformProcedure = TransformProcedure<Data, TokenResponse> {
            return try JSONDecoder().decode(TokenResponse.self, from: $0)
        }
        _transformProcedure.injectPayload(fromNetwork: _networkProcedure)

        self.completion = completion

        super.init(operations: [_networkProcedure, _transformProcedure])

        self.addObserver(NetworkObserver(controller: NetworkActivityController(timerInterval: 1.0, indicator: UIApplication.shared)))
    }

    override func procedureDidFinish(with error: Error?) {
        if error == nil, _transformProcedure.output.success?.errors == nil {
            let keychain = Keychain()
            keychain[LoginViewController.CredentialsKey.email] = email
            keychain[LoginViewController.CredentialsKey.password] = password
            Server.token = _transformProcedure.output.success?.token

            NotificationCenter.default.post(name: Server.didLoginNotification, object: nil)
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

class LoggedInCondition: Condition, LoginViewControllerDelegate {
    enum Error: Swift.Error {
        case noPresentingViewControllerProvided
    }

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
            guard let presentingViewCtrl = presentingViewController else {
                completion(ConditionResult.failure(Error.noPresentingViewControllerProvided))
                return
            }

            let keychain = Keychain()

            if let username = keychain[LoginViewController.CredentialsKey.email],
                let password = keychain[LoginViewController.CredentialsKey.password] {
                let loginProcedure = LoginProcedure(username: username, password: password) { _, error in
                    if error == nil {
                        completion(.success(true))
                    } else {
                        completion(.failure(error!))
                    }
                }

                queue.addOperation(loginProcedure)
            } else {
                DispatchQueue.main.async {
                    
                    let controller: LoginViewController
                    
                    controller = LoginViewController(style: .insetGrouped)
                    
                    controller.delegate = self

                    controller.modalPresentationStyle = .fullScreen

                    presentingViewCtrl.present(controller, animated: true, completion: nil)
                }
            }
        } else {
            completion(.success(true))
        }
    }

    func loginViewControllerDidLogin(_ controller: LoginViewController) {
        DispatchQueue.main.async {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
            self.completion?(.success(true))
        }
    }
}
