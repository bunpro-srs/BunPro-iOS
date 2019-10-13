//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation

public enum Active: String, Codable {
    case yes = "Yes"
    case no = "No"

    public init(from decoder: Decoder) throws {
        guard let value = try? decoder.singleValueContainer().decode(String.self) else {
            self = .no
            return
        }

        guard let state = Active(rawValue: value) else {
            logger.warning("Invalid value for \(Active.self): \(value)")

            switch value {
            case #""On""#, "Show", #""Show""#, #""Yes""#:
                self = .yes

            default:
                self = .no
            }
            return
        }

        self = state
    }
}

public enum Visible: String, Codable {
    case show = "Show"
    case hide = "Hide"
    case minimal = "Minimal"
    case hint = "Hint"
    case nuance = "Always Show Nuance"

    public init(from decoder: Decoder) throws {
        guard let value = try? decoder.singleValueContainer().decode(String.self) else {
            self = .hide
            return
        }

        guard let state = Visible(rawValue: value) else {
            logger.warning("Invalid value for \(Visible.self): \(value)")

            switch value {
            case #""On""#, "Show", #""Show""#:
                self = .show

            case #""Minimal""#:
                self = .minimal

            default:
                self = .hide
            }
            return
        }

        self = state
    }
}

public enum State: String, Codable {
    case on = "On"
    case off = "Off"

    public init(from decoder: Decoder) throws {
        guard let value = try? decoder.singleValueContainer().decode(String.self) else {
            self = .off
            return
        }

        guard let state = State(rawValue: value) else {
            logger.warning("Invalid value for \(State.self): \(value)")

            switch value {
            case #""On""#, "Show", #""Show""#:
                self = .on

            default:
                self = .off
            }
            return
        }

        self = state
    }
}

public enum FuriganaMode: String, Codable {
    case on = "Show"
    case off = "Hide"
    case wanikani = "Wanikani"

    public init?(string: String) {
        guard let mode = FuriganaMode(rawValue: string) else {
            switch string {
            case "Wanikani":
                self = FuriganaMode.wanikani

            case "Hide", "Off":
                self = FuriganaMode.off

            default:
                self = FuriganaMode.on
            }
            return
        }

        self = mode
    }

    public init(from decoder: Decoder) throws {
        guard let value = try? decoder.singleValueContainer().decode(String.self) else {
            self = .off
            return
        }

        guard let state = FuriganaMode(rawValue: value) else {
            logger.warning("Invalid value for \(FuriganaMode.self): \(value)")

            switch value {
            case "On", #""On""#, #""Show""#, "Yes", #""Yes""#:
                self = .on

            case "Wanikani", #""Wanikani""#:
                self = .wanikani

            default:
                self = .off
            }

            return
        }

        self = state
    }
}

public struct BPKAccount: Codable {
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case name = "username"
        case hideEnglish = "hide_english"
        case reviewEnglish = "review_english"
        case bunnyMode = "bunny_mode"
        case furigana
        case subscriber
    }

    public let identifier: Int64
    public let hideEnglish: Active
    public let reviewEnglish: Visible
    public let furigana: FuriganaMode
    public let name: String
    public let bunnyMode: State
    public let subscriber: Bool
}
