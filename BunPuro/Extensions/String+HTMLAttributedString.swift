//
//  String+HTMLAttributedString.swift
//  BunPuro
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
    
    func htmlAttributedString(font: UIFont?) -> NSAttributedString? {
        
        let stringToConvert: String
        
        if let font = font {
            stringToConvert = "<!DOCTYPE html><html><body><span style=\"font-family:Helvetica;font-size:\(font.pointSize)pt\">\(self)</span></body></html>"
        } else {
            stringToConvert = self
        }
        
        guard let data = stringToConvert.data(using: String.Encoding.utf16, allowLossyConversion: false) else { return nil }
        guard let html = try? NSAttributedString(data: data, options: [.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
            else { return nil }
        
        return html
    }
}
