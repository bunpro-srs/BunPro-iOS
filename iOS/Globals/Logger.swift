//
//  Created by Cihat Gündüz on 20.04.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import SwiftyBeaver

let log = SwiftyBeaver.self

final class Logger {
    // MARK: - Stored Type Properties
    static let shared = Logger()

    // MARK: - Instance Properties
    func setup() {
        // configure console logging
        let consoleDestination = ConsoleDestination()

        #if DEBUG
            consoleDestination.minLevel = .debug
        #else
            consoleDestination.minLevel = .warning
        #endif

        log.addDestination(consoleDestination)

        // configure file logging
        let fileDestination = FileDestination()
        fileDestination.minLevel = .info
        log.addDestination(fileDestination)
    }
}
