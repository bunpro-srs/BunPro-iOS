//
//  Created by Andreas Braun on 02.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import UserNotifications

private let nextReviewIdentifier: String = "NextReviewNotification"
private let threadIdentifier: String = "NotificationThreadIdentifier"

struct UserNotificationCenter {
    static let shared = UserNotificationCenter()

    func updateNotifications(basedOnReceived notification: UNNotification) {
        AppDelegate.resetAppBadgeIcon()
    }

    func scheduleNextReviewNotification(at date: Date, reviewCount: Int) {
        guard date > Date() else { return }

        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized,
                 .provisional,
                 .ephemeral:

                DispatchQueue.main.async {
                    let content = UNMutableNotificationContent()
                    content.threadIdentifier = threadIdentifier
                    content.title = L10n.Notification.Review.title(reviewCount)
                    content.sound = UNNotificationSound.default
                    content.badge = AppDelegate.badgeNumber(date: date)

                    let dateComponents = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: date)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let request = UNNotificationRequest(identifier: "\(nextReviewIdentifier)-\(date.timeIntervalSinceNow)", content: content, trigger: trigger)

                    center.add(request) { error in
                        if let error = error {
                            log.error(error)
                        }

                        log.info("Added notification for: \(date)")
                    }
                }
            case .notDetermined,
                 .denied:
                log.info("Unhandled authorization status: \(settings.authorizationStatus)")
            @unknown default:
                log.info("Unknown authorization status: \(settings.authorizationStatus)")
            }
        }
    }
}
