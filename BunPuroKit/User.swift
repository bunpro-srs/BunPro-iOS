import Foundation

public enum Active: String, Codable {
    case yes = "Yes"
    case no = "No"
}

public enum State: String, Codable {
    case on = "On"
    case off = "Off"
}

public enum FuriganaMode: String, Codable {
    case on = "On"
    case off = "Off"
    case wanikani = "Wanikani"
}

public struct User: Codable {
    
    struct Data: Codable {
        
        public struct Attributes: Codable {
            
            public enum CodingKeys: String, CodingKey {
                case name = "username"
                case isActivated = "activated"
                case createdAt = "created-at"
                case updatedAt = "updated-at"
                case bunnyMode = "bunny-mode"
                case furigana
                case hideEnglish = "hide-english"
                case lightMode = "light-mode"
            }
            
            public let name: String
            public let isActivated: Bool
            public let createdAt: Date
            public let updatedAt: Date
            
            public let bunnyMode: State
            public let furigana: FuriganaMode
            public let hideEnglish: Active
            public let lightMode: State
        }
        
        private enum CodingKeys: String, CodingKey {
            case id
            case attributes
        }
        
        let id: String
        let attributes: Attributes
    }
    
    let data: Data
    
    var attributes: Data.Attributes {
        return data.attributes
    }
    
    public var name: String { return attributes.name }
    public var isActivated: Bool  { return attributes.isActivated }
    public var createdAt: Date  { return attributes.createdAt }
    public var updatedAt: Date  { return attributes.updatedAt }
    
    public var bunnyMode: State { return attributes.bunnyMode }
    public var furigana: FuriganaMode { return attributes.furigana }
    public var hideEnglish: Active { return attributes.hideEnglish }
    public var lightMode: State { return attributes.lightMode }
}
