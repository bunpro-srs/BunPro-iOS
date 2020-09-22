//
//  Created by Andreas Braun on 22.09.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import UIKit

protocol IntentionallySelected: AnyObject {
    var intentionallySelected: Bool { get set }
}

class MainSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
    }
    
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
    ) -> Bool {
        guard
            let detail = splitViewController.viewControllers.last?.content as? IntentionallySelected,
            detail.intentionallySelected
        else {
            return true
        }
        
        return false
    }
    
    @available(iOS 14.0, *)
    func splitViewController(
        _ splitViewController: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    ) -> UISplitViewController.Column {
        guard
            let detail = splitViewController.viewController(for: .secondary)?.content as? IntentionallySelected,
            detail.intentionallySelected
        else {
            return .primary
        }
        
        return .secondary
    }
}
