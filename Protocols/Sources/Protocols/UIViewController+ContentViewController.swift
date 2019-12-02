//
//  UIViewController+ContentViewController.swift
//
//  Created by Andreas Braun on 16.01.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit

public protocol ContentViewController { /* only defined for providing extension behavior */ }

extension UIViewController: ContentViewController { }

public extension ContentViewController where Self: UIViewController {
    var content: UIViewController? {
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController
        }

        return self
    }
}
