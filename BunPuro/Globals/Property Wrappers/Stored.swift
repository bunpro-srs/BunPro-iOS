//
//  Created by Andreas Braun on 11.12.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation
import UIKit

@propertyWrapper
struct Stored<T> {
    private let key: String
    private let defaultValue: T

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
