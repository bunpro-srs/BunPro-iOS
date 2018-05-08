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

public struct BPKAccount: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case name = "username"
        case hideEnglish = "hide_english"
        case bunnyMode = "bunny_mode"
        case furigana
        case lightMode = "light_mode"
        case subscriber
    }
    
    public let identifier: Int64
    public let hideEnglish: Active
    public let furigana: FuriganaMode
    public let name: String
    public let lightMode: State
    public let bunnyMode: State
    public let subscriber: Bool
}
