//
//  Created by Cihat Gündüz on 22.04.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation

extension Collection where Iterator.Element == Review {
    public var nextReviewDate: Date? {
        let allDates = filter(\.complete).compactMap(\.nextReviewDate)

        let tmp = allDates.reduce(Date.distantFuture) { $0 < $1 ? $0 : $1 }
        return tmp == Date.distantPast ? nil: tmp
    }

    public func reviews(in range: Range<Date>) -> [Review] {
        filter { $0.complete && $0.nextReviewDate! >= range.lowerBound && $0.nextReviewDate! < range.upperBound }
    }

    public func reviews(at date: Date) -> [Review] {
        let result = filter { $0.complete && $0.nextReviewDate!.minutes(from: date) <= 0 }
        return result
    }

    public var reviewsWithinNextHour: Int {
        reviewsWithinNextHour(from: Date())
    }

    public func reviewsWithinNextHour(from date: Date) -> Int {
        let result = filter { $0.complete && $0.nextReviewDate!.minutes(from: date) < 60 }
        return result.count
    }

    public var reviewsWithNext24Hours: Int {
        let date = Date()
        let result = filter { $0.complete && $0.nextReviewDate!.hours(from: date) <= 23 }
        return result.count
    }
}