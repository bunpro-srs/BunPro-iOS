//
//  Created by Andreas Braun on 23.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

final class StreakInfoCell: UITableViewCell {
    
    @IBOutlet private weak var contentStackView: UIStackView!
    @IBOutlet private var hankoCollection: [UIImageView]!
    
    var streak: Int = 0
    
    override func layoutSubviews() {
        
        for (index, hanko) in hankoCollection.enumerated() {
            
            hanko.tintColor = .lightGray
            hanko.alpha = (index + 1) <= streak ? 1.0 : 0.1
        }
        
        super.layoutSubviews()
    }
}
