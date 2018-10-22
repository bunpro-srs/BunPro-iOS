//
//  ActivateTrialPeriodProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 06.05.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

public final class ActivateTrialPeriodProcedure: BunPuroProcedure<BPKAccount> {
    override var url: URL  { return URL(string: "\(baseUrlString)user/sign_up_for_trial")! }
}
