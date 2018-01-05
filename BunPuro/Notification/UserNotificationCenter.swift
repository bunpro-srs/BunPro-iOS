//
//  UserNotificationCenter.swift
//  BunPuro
//
//  Created by Andreas Braun on 02.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import UserNotifications

struct UserNotificationCenter {
    
    static let shared = UserNotificationCenter()
    
    func scheduleNextReviewNotification(at date: Date) {
        
        guard date > Date() else { return }
        
        let center = UNUserNotificationCenter.current()
        
        let identifier = "NextReviewNotification"
        
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification.review.title", comment: "")
        content.body = NSLocalizedString("notification.review.message", comment: "")
        content.sound = UNNotificationSound.default()
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: date), repeats: false)
    
        
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        center.add(request, withCompletionHandler: { (error) in
            if let error = error {
                print(error)
            }
            
            print("Added notification for: \(date)")
        })
    }
}
