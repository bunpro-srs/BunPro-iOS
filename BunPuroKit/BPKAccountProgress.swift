//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation

public struct BPKAccountProgress: Codable {
    public struct JLPT {
        public let name: String
        public let current: Int
        public let max: Int

        public var progress: Float {
            guard max > 0 else { return 0.0 }

            return Float(current) / Float(max)
        }

        public var localizedProgress: String? {
            return "\(current) / \(max)"
        }
    }

    // swiftlint:disable identifier_name
    let N5: [Int]
    let N4: [Int]
    let N3: [Int]
    let N2: [Int]

    public var n5: JLPT {
        return JLPT(name: "N5", current: N5[0], max: N5[1])
    }

    public var n4: JLPT {
        return JLPT(name: "N4", current: N4[0], max: N4[1])
    }

    public var n3: JLPT {
        return JLPT(name: "N3", current: N3[0], max: N3[1])
    }

    public var n2: JLPT {
        return JLPT(name: "N2", current: N2[0], max: N2[1])
    }
    // swiftlint:enable identifier_name
}
