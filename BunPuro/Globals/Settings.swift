//
//  Created by Andreas Braun on 11.12.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation

enum Settings {
    @Stored(key: "lastDatabaseUpdate", defaultValue: Date(timeIntervalSince1970: 0))

    static var lastDatabaseUpdate: Date
}
