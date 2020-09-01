//
//  Created by Andreas Braun on 01.11.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Foundation

struct Paragraph: Decodable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case headline
        case content
        case bulletpoints
    }

    let id = UUID()
    let headline: String?
    let content: String?
    let bulletpoints: [String]?
}
