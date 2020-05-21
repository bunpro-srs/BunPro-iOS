//
//  Created by Andreas Braun on 01.12.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 13.0, *)
extension UIImage {
    private enum SystemName: String {
        case pencilCircle = "pencil.circle"
        case pencilCircleFill = "pencil.circle.fill"
        case magnifyingglassCircle = "magnifyingglass.circle"
        case magnifyingglassCircleFill = "magnifyingglass.circle.fill"
        case ellipsisCircle = "ellipsis.circle"
        case ellipsisCircleFill = "ellipsis.circle.fill"
        case playCircle = "play.circle"
        case trashFill = "trash.fill"
        case `repeat` = "repeat"
        case repeatOne = "repeat.1" // swiftlint:disable:this tuple_index
        case docOnDocFill = "doc.on.doc.fill"

        var image: UIImage {
            UIImage(systemName: self.rawValue)!
        }
    }

    static let pencilCircle: UIImage = SystemName.pencilCircle.image
    static let pencilCircleFill: UIImage = SystemName.pencilCircleFill.image
    static let magnifyingglassCircle: UIImage = SystemName.magnifyingglassCircle.image
    static let magnifyingglassCircleFill: UIImage = SystemName.magnifyingglassCircleFill.image
    static let ellipsisCircle: UIImage = SystemName.ellipsisCircle.image
    static let ellipsisCircleFill: UIImage = SystemName.ellipsisCircleFill.image
    static let playCircle: UIImage = SystemName.playCircle.image
    static let trashFill: UIImage = SystemName.trashFill.image
    static let `repeat`: UIImage = SystemName.`repeat`.image
    static let repeatOne: UIImage = SystemName.repeatOne.image
    static let docOnDocFill: UIImage = SystemName.docOnDocFill.image
}
