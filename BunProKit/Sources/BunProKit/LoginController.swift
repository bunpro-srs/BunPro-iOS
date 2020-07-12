//
//  LoginController.swift
//  BunproSRS
//
//  Created by Andreas Braun on 11.07.20.
//

import Combine
import Foundation
import KeychainAccess

enum CredentialKey {
    static let email = "email"
    static let password = "password"
    static let token = "token"
}

class LoginController: ObservableObject {
    
    enum State {
        case loggedOut
        case loggingIn
        case loginFailed
        case loggedIn
    }
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var state: State = .loggedOut
    
    var hasValidCredential = CurrentValueSubject<Bool, Never>(false)
        
    private var didLoginHandler: () -> Void
    
    private let keychain = Keychain()
    private var subscriptions = Set<AnyCancellable>()
    
    init(loginHandler: @escaping () -> Void) {
        
        self.didLoginHandler = loginHandler
        
        $email.combineLatest($password)
            .map { (result) -> Bool in
                !result.0.isEmpty && !result.1.isEmpty
            }
            .assign(to: \.value, on: hasValidCredential)
            .store(in: &subscriptions)
        
        email = keychain[string: CredentialKey.email] ?? ""
        password = keychain[string: CredentialKey.password] ?? ""
    }
    
    func login() {
        DispatchQueue.main.async {
            self.state = .loggingIn
        }

        let loginProcedure = LoginProcedure(username: email, password: password) { _, error in
            DispatchQueue.main.async { [weak self] in
                guard error == nil else {
                    self?.state = .loginFailed
                    return
                }
                
                self?.state = .loggedIn
                self?.didLoginHandler()
            }
        }
        
        NetworkHandler.shared.queue.addOperation(loginProcedure)
    }
    
    private func validateCredential() -> Bool {
        !email.isEmpty && !password.isEmpty
    }
}
