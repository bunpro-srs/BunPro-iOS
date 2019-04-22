//
//  Created by Andreas Braun on 15.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import KeychainAccess
import ProcedureKit
import ProcedureKitNetwork

private let logoutUrlString = "\(baseUrlString)logout"

final class LogoutProcedure: Procedure {
    // TODO: either uncomment or remove this code – or explain why it should be kept
    //private let _networkProcedure: NetworkProcedure<NetworkDataProcedure<URLSession>>

    override func execute() {
        let keychain = Keychain()
        keychain[LoginViewController.CredentialsKey.password.rawValue] = nil
        Server.token = nil

        NotificationCenter.default.post(name: .ServerDidLogoutNotification, object: nil)

        finish()
    }
}

public extension Notification.Name {
    static let ServerDidLogoutNotification = Notification.Name(rawValue: "ServerDidLogoutNotification")
}
