//
//  UserNotificationCenter.swift
//  BunPuro
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
    
    func scheduleNextReviewNotification(at date: Date) {
        
        guard date > Date() else { return }
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.threadIdentifier = threadIdentifier
        content.title = NSLocalizedString("notification.review.title", comment: "")
        content.body = NSLocalizedString("notification.review.message", comment: "")
        content.sound = UNNotificationSound.default()
        content.badge = AppDelegate.badgeNumber(date: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: date), repeats: false)
        
        let request = UNNotificationRequest(identifier: nextReviewIdentifier,
                                            content: content, trigger: trigger)
        center.add(request) { (error) in
            if let error = error {
                print(error)
            }
            
            print("Added notification for: \(date)")
        }
    }
}
