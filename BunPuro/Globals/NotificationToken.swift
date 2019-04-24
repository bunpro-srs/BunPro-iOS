//
//  Created by Cihat Gündüz on 24.04.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//
//  Originally copied from: https://oleb.net/blog/2018/01/notificationcenter-removeobserver/
//

import Foundation

/// Wraps the observer token received from NotificationCenter.observe(name:object:queue:using:) and unregisters it in deinit.
final class NotificationToken: NSObject {
    let token: Any
    let notificationCenter: NotificationCenter

    init(token: Any, notificationCenter: NotificationCenter = .default) {
        self.token = token
        self.notificationCenter = notificationCenter
    }

    deinit {
        notificationCenter.removeObserver(token)
    }
}
