//
//  Created by Andreas Braun on 04.05.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Foundation

extension Date {
    init(day: Int, month: Int, year: Int) {
        var component = DateComponents()
        component.year = year
        component.month = month
        component.day = day

        self.init(timeIntervalSince1970: Calendar.autoupdatingCurrent.date(from: component)!.timeIntervalSince1970)
    }
}
