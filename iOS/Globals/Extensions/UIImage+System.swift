//
//  Created by Andreas Braun on 01.12.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    private enum SystemName: String {
        case ellipsisCircle = "ellipsis.circle"
        case playCircle = "play.circle"
        case trashFill = "trash.fill"
        case `repeat` = "repeat"
        case repeatOne = "repeat.1" // swiftlint:disable:this tuple_index
        case docOnDocFill = "doc.on.doc.fill"

        var image: UIImage {
            UIImage(systemName: self.rawValue)!
        }
    }

    static let ellipsisCircle: UIImage = SystemName.ellipsisCircle.image
    static let playCircle: UIImage = SystemName.playCircle.image
    static let trashFill: UIImage = SystemName.trashFill.image
    static let `repeat`: UIImage = SystemName.`repeat`.image
    static let repeatOne: UIImage = SystemName.repeatOne.image
    static let docOnDocFill: UIImage = SystemName.docOnDocFill.image
}
