//
//  Created by Cihat Gündüz on 22.04.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation

extension Date {
    func minutes(from date: Date) -> Int {
        Calendar.autoupdatingCurrent.dateComponents([.minute], from: date, to: self).minute!
    }

    func hours(from date: Date) -> Int {
        Calendar.autoupdatingCurrent.dateComponents([.hour], from: date, to: self).hour!
    }

    var inOneHour: Date {
        Calendar.autoupdatingCurrent.date(byAdding: .hour, value: 1, to: self)!
    }

    var tomorrow: Date {
        Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: noon)!
    }

    var noon: Date {
        Calendar.autoupdatingCurrent.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }

    var nextMidnight: Date {
        Calendar.autoupdatingCurrent.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
}
