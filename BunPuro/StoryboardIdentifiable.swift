//
//  StoryboardIdentifiable
//
//
//  Created by Andreas Braun on 19.12.16.
//
//

import UIKit

protocol StoryboardIdentifiable { }

extension StoryboardIdentifiable where Self: UIViewController {
    static var storyboardIdentifier: String {
        return String(describing: self)
    }
}

extension UIViewController: StoryboardIdentifiable { }

extension UIStoryboard {
    func instantiateViewController<T: UIViewController>() -> T {
        guard let viewController = instantiateViewController(withIdentifier: T.storyboardIdentifier) as? T else {
            fatalError("Could not instantiate View Controller with identifier: \(T.storyboardIdentifier)")
        }
        return viewController
    }
}
