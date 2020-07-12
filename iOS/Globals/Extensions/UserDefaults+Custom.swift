//
//  Created by Andreas Braun on 05.10.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation
import UIKit

extension UserDefaults {
    var lastDatabaseUpdate: Date {
        get { Date(timeIntervalSince1970: double(forKey: "lastDatabaseUpdate")) }
        set { set(newValue.timeIntervalSince1970, forKey: "lastDatabaseUpdate") }
    }
}

extension UserDefaults {
    @objc
    enum UserInterfaceStyle: Int {
        case system
        case light
        case dark
        case bunpro

        var systemStyle: UIUserInterfaceStyle {
            switch self {
            case .system:
                return .unspecified

            case .light:
                return .light

            case .dark:
                return .dark

            case .bunpro:
                return Account.currentAccount?.lightMode == true ? .light : .dark
            }
        }

        var localizedTitle: String {
            switch self {
            case .system:
                return "System"
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            case .bunpro:
                return "Bunpro Theme"
            }
        }
    }

    @objc
    dynamic
    var userInterfaceStyle: UserInterfaceStyle {
        get { UserInterfaceStyle(rawValue: integer(forKey: "userInterfaceStyle")) ?? .system }
        set { set(newValue.rawValue, forKey: "userInterfaceStyle") }
    }
}
