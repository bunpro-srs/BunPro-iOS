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
private let nextReviewReminderIdentifier = "NextReviewReminderNotification"

struct UserNotificationCenter {
    
    static let shared = UserNotificationCenter()
    
    func updateNotifications(basedOnReceived notification: UNNotification) {
        
        if notification.request.identifier == nextReviewReminderIdentifier {
            let center = UNUserNotificationCenter.current()
            
            center.removeDeliveredNotifications(withIdentifiers: [nextReviewIdentifier])
        }
        
        AppDelegate.resetAppBadgeIcon()
    }
    
    func scheduleNextReviewNotification(at date: Date) {
        
        guard date > Date() else { return }
        
        let center = UNUserNotificationCenter.current()
        
        center.removeDeliveredNotifications(withIdentifiers: [nextReviewIdentifier])
        center.removePendingNotificationRequests(withIdentifiers: [nextReviewIdentifier])
        
        let content = UNMutableNotificationContent()
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
        
        scheduleReminderNotification(from: date)
    }
    
    private func scheduleReminderNotification(from date: Date) {
        guard date > Date() else { return }
        
        let reminderDate = date.addingTimeInterval(10)
        
        let center = UNUserNotificationCenter.current()
        
        center.removeDeliveredNotifications(withIdentifiers: [nextReviewReminderIdentifier])
        center.removePendingNotificationRequests(withIdentifiers: [nextReviewReminderIdentifier])
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.review.title", comment: "")
        content.body = NSLocalizedString("notification.review.message", comment: "")
        content.sound = UNNotificationSound.default()
        content.badge = AppDelegate.badgeNumber(date: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: reminderDate), repeats: false)
        
        let request = UNNotificationRequest(identifier: nextReviewReminderIdentifier,
                                            content: content, trigger: trigger)
        center.add(request) { (error) in
            if let error = error {
                print(error)
            }
            
            print("Added notification reminder for: \(reminderDate)")
        }
    }
}
