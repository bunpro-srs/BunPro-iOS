//
//  GrammarPoint.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation

public struct GrammarPointResponse: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case grammarPoints = "data"
    }
    
    public let grammarPoints: [GrammarPoint]
}

public struct GrammarPoint: Codable {
    
    struct Attributes: Codable {
        let title: String
        let meaning: String
    }
    
    public let id: String
    
    private let attributes: Attributes
    
    public var title: String {
        return attributes.title
    }
    
    public var meaning: String {
        return attributes.meaning
    }
}
