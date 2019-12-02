//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit


public final class ProgressProcedure: BunPuroProcedure<BPKAccountProgress> {
    override var url: URL { return URL(string: "\(baseUrlString)/user/progress")! }
}
