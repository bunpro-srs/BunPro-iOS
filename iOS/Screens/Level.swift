//
//  Created by Andreas Braun on 19.07.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import Foundation

struct Level: Identifiable {
    var id = UUID()
    var name: String
    var completedGrammar: Int
    var totalGrammar: Int

    var progress: Double {
        guard totalGrammar > 0 else { return 0.0 }
        return Double(completedGrammar) / Double(totalGrammar)
    }
}
