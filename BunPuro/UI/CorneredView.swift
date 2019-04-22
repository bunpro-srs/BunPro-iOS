//
//  Created by Andreas Braun on 13.04.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

@IBDesignable
final class CorneredView: UIView {
    @IBInspectable var cornerRadius: CGFloat = 4.0 {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var minXminYCornerMasked: Bool = true {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var minXmaxYCornerMasked: Bool = true {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var maxXminYCornerMasked: Bool = true {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var maxXmaxYCornerMasked: Bool = true {
        didSet { setNeedsDisplay() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.6
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.masksToBounds = false
        clipsToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = cornerRadius
        layer.maskedCorners = maskedCorners
    }

    private var maskedCorners: CACornerMask {
        var value: UInt = 0

        if minXminYCornerMasked { value += 1 }
        if maxXminYCornerMasked { value += 2 }
        if minXmaxYCornerMasked { value += 4 }
        if maxXmaxYCornerMasked { value += 8 }

        return CACornerMask(rawValue: value)
    }
}
