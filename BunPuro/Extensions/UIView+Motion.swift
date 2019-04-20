//
//  Created by Andreas Braun on 16.04.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

extension UIView {
    
    func addMotion(ofMagnitude magnitude: Float = 10) {
        
        let xMotion = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        xMotion.minimumRelativeValue = -magnitude
        xMotion.maximumRelativeValue = magnitude
        
        let yMotion = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        yMotion.minimumRelativeValue = -magnitude
        yMotion.maximumRelativeValue = magnitude
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [xMotion, yMotion]
        
        addMotionEffect(group)
    }
}
