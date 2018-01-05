//
//  String+Furigana.swift
//  BunPuro
//
//  Created by Andreas Braun on 28.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import CoreText

extension String {
    
    func attributedStringWithRuby() -> NSMutableAttributedString {
        
        // "｜": ルビを振る対象の文字列を判定し区切る為の記号(全角). ルビを振る文字列の先頭に挿入する
        // "《》": ルビを振る対象の漢字の直後に挿入しルビを囲う(全角)
        
        let attributed =
            self.replace(pattern: "(｜.+?《.+?》)", template: ",$1,")
                .components(separatedBy: ",")
                .map { x -> NSAttributedString in
                    if let pair = x.find(pattern: "｜(.+?)《(.+?)》") {
                        let string = (x as NSString).substring(with: pair.range(at: 1))
                        let ruby = (x as NSString).substring(with: pair.range(at: 2))
                        
                        var text = [.passRetained(ruby as CFString) as Unmanaged<CFString>?, .none, .none, .none]
                        let annotation = CTRubyAnnotationCreate(.auto, .auto, 0.5, &text[0])
                        
                        return NSAttributedString(
                            string: string,
                            attributes: [kCTRubyAnnotationAttributeName as NSAttributedStringKey: annotation])
                    } else {
                        return NSAttributedString(string: x, attributes: nil)
                    }
                }
                .reduce(NSMutableAttributedString()) { $0.append($1); return $0 }
        
        return attributed
    }
    
    func find(pattern: String) -> NSTextCheckingResult? {
        do {
            let re = try NSRegularExpression(pattern: pattern, options: [])
            return re.firstMatch(
                in: self,
                options: [],
                range: NSMakeRange(0, self.utf16.count))
        } catch {
            return nil
        }
    }
    
    func replace(pattern: String, template: String) -> String {
        do {
            let re = try NSRegularExpression(pattern: pattern, options: [])
            return re.stringByReplacingMatches(
                in: self,
                options: [],
                range: NSMakeRange(0, self.utf16.count),
                withTemplate: template)
        } catch {
            return self
        }
    }
}
