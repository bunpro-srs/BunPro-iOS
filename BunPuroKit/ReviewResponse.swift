//
//  ReviewResponse.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 31.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation

public struct ReviewResponse: Codable {
    
    public let data: [Review]
    
    public var nextReviewDate: Date? {
        
        let allDates = data.flatMap { $0.attributes.lastStudiedAt }
        
        let tmp = allDates.reduce(Date.distantPast, { $0 > $1 ? $0 : $1 }).localizedDate
        return tmp == Date.distantPast ? nil: tmp
    }
    
    public var reviewsWithinNextHour: Int {
        
        let date = Date()
        let result = data.filter({ $0.attributes.complete && $0.attributes.nextReviewDate.localizedDate.hours(from: date) <= 0 })
        return result.count
    }
    
    public var reviewsTomorrow: Int {
        
        return data.filter({ $0.attributes.complete && $0.attributes.nextReviewDate.isTomorrow() }).count
    }
}

extension Date {
    
    func hours(from date: Date) -> Int {
        
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour!
    }
    
    func isTomorrow() -> Bool {
        
        return Calendar.current.isDateInTomorrow(self)
    }
    
    var localizedDate: Date {
        
        return addingTimeInterval(TimeInterval(TimeZone.current.secondsFromGMT()))
    }
}
