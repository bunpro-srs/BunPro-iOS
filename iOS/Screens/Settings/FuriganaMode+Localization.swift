//
//  Created by Andreas Braun on 24.07.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import BunProKit
import Foundation

extension FuriganaMode {
    init(localizedString: String) {
        switch localizedString {
        case L10n.Furigana.on:
            self = .on

        case L10n.Furigana.off:
            self = .off

        case L10n.Furigana.wanikani:
            self = .wanikani

        default:
            self = .on
        }
    }

    var localizedString: String {
        switch self {
        case .on:
            return L10n.Furigana.on

        case .off:
            return L10n.Furigana.off

        case .wanikani:
            return L10n.Furigana.wanikani
        }
    }
}
