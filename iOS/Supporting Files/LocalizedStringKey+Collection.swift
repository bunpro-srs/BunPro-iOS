//
//  Created by Andreas Braun on 24.07.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import SwiftUI

extension LocalizedStringKey {
    enum Information {
        enum Category {
            static let about: LocalizedStringKey = "information.category.about"
            static let privacy: LocalizedStringKey = "information.category.privacy"
            static let terms: LocalizedStringKey = "information.category.terms"
        }
    }

    enum Settings {
        enum Configuration {
            static let furigana: LocalizedStringKey = "settings.configuration.furigana"
            static let hideTranslation: LocalizedStringKey = "settings.configuration.hidetranslation"
            static let automaticAdvancement: LocalizedStringKey = "settings.configuration.automaticadvancement"
            static let userInterfaceAppearance: LocalizedStringKey = "settings.configuration.userinterfaceappearance"
        }

        static let logout: LocalizedStringKey = "settings.logout.action"
        static let community: LocalizedStringKey = "settings.community.action"
        static let contact: LocalizedStringKey = "settings.contact.action"
    }
}
