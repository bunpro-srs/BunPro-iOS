//
//  Created by Andreas Braun on 11.12.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation

@propertyWrapper
public struct Trimmed {
    private(set) var value: String = ""

    public var wrappedValue: String {
        get { value }
        set { value = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }
}
