//
//  Created by Andreas Braun on 28.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import CoreText

extension String {
    
    /// 「漢字」かどうか
    var isKanji: Bool {
        let range = "^[\u{3005}\u{3007}\u{303b}\u{3400}-\u{9fff}\u{f900}-\u{faff}\u{20000}-\u{2ffff}]+$"
        return NSPredicate(format: "SELF MATCHES %@", range).evaluate(with: self)
    }
    
    /// 「ひらがな」かどうか
    var isHiragana: Bool {
        let range = "^[ぁ-ゞ]+$"
        return NSPredicate(format: "SELF MATCHES %@", range).evaluate(with: self)
    }
    
    /// 「カタカナ」かどうか
    var isKatakana: Bool {
        let range = "^[ァ-ヾ]+$"
        return NSPredicate(format: "SELF MATCHES %@", range).evaluate(with: self)
    }
    
    /// 「ひらがな」に変換 ※１
    var toHiragana: String? {
        return self.applyingTransform(.hiraganaToKatakana, reverse: false)
    }
    
    /// 「カタカナ」に変換
    var toKatakana: String? {
        return self.applyingTransform(.hiraganaToKatakana, reverse: true)
    }
    
    /// 「ひらがな」を含むかどうか ※2
    var hasHiragana: Bool {
        guard let hiragana = self.toKatakana else { return false }
        return self != hiragana // １文字でもカタカナに変換されている場合は含まれると断定できる
    }
    
    /// 「カタカナ」を含むかどうか
    var hasKatakana: Bool {
        guard let katakana = self.toHiragana else { return false }
        return self != katakana // １文字でもひらがなに変換されている場合は含まれると断定できる
    }
}

extension String {
    
    var cleanStringAndFurigana: (string: String, furigana: [Furigana]?) {
        var foundKanji = false
        var foundFurigana = false
        
        var currentKanjiWord = ""
        var currentFuriganaWord = ""
        
        var furiganas: [Furigana]?
        
        var pairs: [(kanji: String, furigana: String)] = []
        
        for character in self {
            
            switch character {
            case "（":
                foundFurigana = true
                foundKanji = false
            case "）":
                foundFurigana = false
                foundKanji = false
                pairs += [
                    (kanji: currentKanjiWord,
                     furigana: currentFuriganaWord)
                ]
                
                currentFuriganaWord = ""
                currentKanjiWord = ""
            default:
                
                let characterString = String(character)
                
                guard characterString.isKanji || characterString.isHiragana || characterString.isKatakana else {
                    
                    currentKanjiWord = ""
                    continue
                }
                
                if !foundKanji {
                    foundKanji = characterString.isKanji
                }
                
                if foundKanji {
                    currentKanjiWord += String(character)
                }
                if foundFurigana {
                    currentFuriganaWord += String(character)
                }
            }
        }
        
        var correctedText = self
        
        for pair in pairs {
            correctedText = correctedText.replacingOccurrences(of: "（\(pair.furigana)）", with: "")
        }
        
        for pair in pairs {
            
            guard let r = correctedText.range(of: pair.kanji) else { continue }
            
            let range = NSRange(r, in: correctedText)
            let furigana = Furigana(text: pair.furigana, original: pair.kanji, range: range)
            
            if furiganas == nil {
                furiganas = [furigana]
            } else {
                furiganas! += [furigana]
            }
        }
        
        return (correctedText, furiganas)
    }
}
