//
//  Created by Andreas Braun on 05.10.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation

extension UserDefaults {
    var lastDatabaseUpdate: Date {
        get {
            return Date(timeIntervalSince1970: double(forKey: "lastDatabaseUpdate"))
        }

        set {
            set(newValue.timeIntervalSince1970, forKey: "lastDatabaseUpdate")
        }
    }
}
