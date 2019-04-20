//
//  UserProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import ProcedureKit
import ProcedureKitNetwork

public final class UserProcedure: BunPuroProcedure<BPKAccount> {
    override var url: URL { return URL(string: "\(baseUrlString)user/")! }
}
