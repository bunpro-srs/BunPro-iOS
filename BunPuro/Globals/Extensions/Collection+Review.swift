//
//  Created by Cihat Gündüz on 22.04.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation

extension Collection where Iterator.Element == Review {
    public var nextReviewDate: Date? {
        let allDates = filter { $0.complete }.compactMap { $0.nextReviewDate }

        let tmp = allDates.reduce(Date.distantFuture) { $0 < $1 ? $0 : $1 }
        return tmp == Date.distantPast ? nil: tmp
    }

    public func reviews(at date: Date) -> [Review] {
        let result = filter { $0.complete && $0.nextReviewDate!.minutes(from: date) <= 0 }
        return result
    }

    public var reviewsWithinNextHour: Int {
        let date = Date()
        let result = filter { $0.complete && $0.nextReviewDate!.minutes(from: date) < 60 }
        return result.count
    }

    public var reviewsWithNext24Hours: Int {
        let date = Date()
        let result = filter { $0.complete && $0.nextReviewDate!.hours(from: date) <= 23 }
        return result.count
    }
}
