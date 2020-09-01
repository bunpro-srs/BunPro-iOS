//
//  Created by Andreas Braun on 01.09.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import SwiftUI

extension Image {
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
        case studentdesk = "studentdesk"

        var image: Image {
            Image(systemName: self.rawValue)
        }
    }

    static let pencilCircle: Image = SystemName.pencilCircle.image
    static let pencilCircleFill: Image = SystemName.pencilCircleFill.image
    static let magnifyingglassCircle: Image = SystemName.magnifyingglassCircle.image
    static let magnifyingglassCircleFill: Image = SystemName.magnifyingglassCircleFill.image
    static let ellipsisCircle: Image = SystemName.ellipsisCircle.image
    static let ellipsisCircleFill: Image = SystemName.ellipsisCircleFill.image
    static let playCircle: Image = SystemName.playCircle.image
    static let trashFill: Image = SystemName.trashFill.image
    static let `repeat`: Image = SystemName.`repeat`.image
    static let repeatOne: Image = SystemName.repeatOne.image
    static let docOnDocFill: Image = SystemName.docOnDocFill.image
    static let studentdesk: Image = SystemName.studentdesk.image
}
