//
//  LessonsProcedure.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation

public final class GrammarPointsProcedure: BunPuroProcedure<[BPKGrammar]> {
    override var hasMilliseconds: Bool { return true }
    override var url: URL { return URL(string: "\(baseUrlString)grammar_points")! }
}
