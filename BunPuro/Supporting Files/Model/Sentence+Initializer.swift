//
//  Created by Andreas Braun on 22.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import BunPuroKit
import CoreData
import Foundation

extension Sentence {
    @discardableResult
    convenience init(sentence: BPKSentence, grammar: Grammar, context: NSManagedObjectContext) {
        self.init(context: context)

        identifier = sentence.identifier
        japanese = sentence.japanese
        english = sentence.english
        structure = sentence.structure
        createdDate = sentence.createdDate
        updatedDate = sentence.updatedDate
        alternativeJapanese = sentence.alternativeJapanese
        audio = sentence.audio
        self.grammar = grammar
    }

    var audioURL: URL? {
        guard let fileName = audio?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "https://bunpro.jp/audio/\(fileName)")
    }
}
