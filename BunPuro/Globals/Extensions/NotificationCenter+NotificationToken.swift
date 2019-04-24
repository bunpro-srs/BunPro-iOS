//
//  Created by Cihat Gündüz on 24.04.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//
//  Originally copied from: https://oleb.net/blog/2018/01/notificationcenter-removeobserver/
//

import Foundation

extension NotificationCenter {
    /// Convenience wrapper for addObserver(forName:object:queue:using:) that returns our custom NotificationToken.
    func observe(name: NSNotification.Name?, object: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NotificationToken {
        let token = addObserver(forName: name, object: object, queue: queue, using: block)
        return NotificationToken(token: token, notificationCenter: self)
    }
}
