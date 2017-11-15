//
//  Server+Convenience.swift
//  BunPuro
//
//  Created by Andreas Braun on 14.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import BunPuroKit

extension Server {
    
    static func updateStatus(completion: @escaping (Error?) -> Void) {
        updateStatus(indicator: UIApplication.shared, completion: completion)
    }
}
