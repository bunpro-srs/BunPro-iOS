//
//  LoginView.swift
//  BunproSRS
//
//  Created by Andreas Braun on 11.07.20.
//

import SwiftUI

struct LoginView: View {
    
    @ObservedObject var loginController: LoginController
    @ObservedObject private var keyboardResponder = KeyboardResponder()
    
    var body: some View {
        VStack(spacing: 20) {
            VStack {
                TextField("Email", text: $loginController.email)
                    .textContentType(.emailAddress)
                    .disabled(loginController.state == .loggingIn || loginController.state == .loggedIn)
                Divider()
                SecureField("Password", text: $loginController.password)
                    .textContentType(.password)
                    .disabled(loginController.state == .loggingIn || loginController.state == .loggedIn)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(loginController.state == .loginFailed ? Color.red : Color.clear, lineWidth: 2)
            )
            
            Button(loginController.state == .loggingIn ? "Logging in..." : "Login", action: loginController.login)
                .buttonStyle(LoginButtonStyle())
                .disabled(!loginController.hasValidCredential.value || loginController.state == .loggingIn || loginController.state == .loggedIn)            
        }
        .frame(maxWidth: 414)
        .padding()
        .padding(.bottom, keyboardResponder.currentHeight)
        
        .animation(.default)
    }
}

struct LoginButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.white)
            .padding()
            .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color.accentColor)
            )
            .scaleEffect(configuration.isPressed ? 0.95: 1)
            .animation(.spring())
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(loginController: LoginController(loginHandler: {}))
    }
}
