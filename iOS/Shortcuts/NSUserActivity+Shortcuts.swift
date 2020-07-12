//
//  Created by Andreas Braun on 22.10.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import CoreSpotlight
import Foundation
import Intents
import MobileCoreServices

extension NSUserActivity {
    enum ActivityType: String {
        case study = "com.bunpro.activity.study"
        case cram = "com.bunpro.activity.cram"
    }

    static var studyActivity: NSUserActivity {
        let activity = NSUserActivity(activityType: ActivityType.study.rawValue)
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true

        activity.title = L10n.Shortcut.Study.title
        activity.suggestedInvocationPhrase = NSString.deferredLocalizedIntentsString(with: "shortcut.study.suggetedphrase") as String
        activity.userInfo = ["value": "key"]

        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        attributes.keywords = ["japanese", "grammar", "learn", "study"]

        activity.contentAttributeSet = attributes

        return activity
    }

    static var cramActivity: NSUserActivity {
        let activity = NSUserActivity(activityType: ActivityType.cram.rawValue)
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true

        activity.title = L10n.Shortcut.Cram.title
        activity.suggestedInvocationPhrase = NSString.deferredLocalizedIntentsString(with: "shortcut.cram.suggetedphrase") as String
        activity.userInfo = ["value": "key"]

        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        attributes.keywords = ["japanese", "grammar", "learn", "study"]

        activity.contentAttributeSet = attributes

        return activity
    }
}
