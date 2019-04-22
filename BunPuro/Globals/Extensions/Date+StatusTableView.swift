//
//  Created by Cihat Gündüz on 22.04.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation

extension Date {
    func minutes(from date: Date) -> Int {
        return Calendar.autoupdatingCurrent.dateComponents([.minute], from: date, to: self).minute!
    }

    func hours(from date: Date) -> Int {
        return Calendar.autoupdatingCurrent.dateComponents([.hour], from: date, to: self).hour!
    }

    func isTomorrow() -> Bool {
        return Calendar.autoupdatingCurrent.isDateInTomorrow(self)
    }

    var tomorrow: Date {
        return Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: noon)!
    }

    var noon: Date {
        return Calendar.autoupdatingCurrent.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }

    var nextMidnight: Date {
        return Calendar.autoupdatingCurrent.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
}
