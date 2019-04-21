//
//  Created by Andreas Braun on 02.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import UserNotifications

private let nextReviewIdentifier = "NextReviewNotification"
private let threadIdentifier = "NotificationThreadIdentifier"

struct UserNotificationCenter {
    static let shared = UserNotificationCenter()

    func updateNotifications(basedOnReceived notification: UNNotification) {
        AppDelegate.resetAppBadgeIcon()
    }

    func scheduleNextReviewNotification(at date: Date, reviewCount: Int) {
        guard date > Date() else { return }

        DispatchQueue.main.async {
            let center = UNUserNotificationCenter.current()

            let content = UNMutableNotificationContent()
            content.threadIdentifier = threadIdentifier
            content.title = L10n.Notification.Review.title(reviewCount)
            //        content.body = L10n.Notification.Review.message
            content.sound = UNNotificationSound.default
            content.badge = AppDelegate.badgeNumber(date: date)

            let dateComponents = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: nextReviewIdentifier, content: content, trigger: trigger)

            center.removeAllDeliveredNotifications()

            center.add(request) { error in
                if let error = error {
                    log.error(error)
                }

                log.info("Added notification for: \(date)")
            }
        }
    }
}
