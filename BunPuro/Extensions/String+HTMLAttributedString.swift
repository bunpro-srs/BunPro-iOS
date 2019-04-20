//
//  Created by Andreas Braun on 21.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import UIKit

extension String {
    
    var htmlAttributedString: NSAttributedString? {
        return htmlAttributedString(font: nil)
    }
    
    func htmlAttributedString(font: UIFont?, color: UIColor = .black) -> NSAttributedString? {
        
        let stringToConvert: String
        
        if let font = font {
            stringToConvert = "<!DOCTYPE html><html><body><span style=\"font-family:system-ui;font-size:\(font.pointSize)pt\">\(self)</span></body></html>"
        } else {
            stringToConvert = self
        }
        
        guard let data = stringToConvert.data(using: String.Encoding.utf16, allowLossyConversion: false) else { return nil }
        guard let html = try? NSMutableAttributedString(data: data, options: [.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
            else { return nil }
        
        html.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(location: 0, length: html.length))
        return html
    }
}
