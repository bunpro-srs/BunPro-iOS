//
//  Created by Andreas Braun on 19.12.16.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit

// MARK: ReusableView
public protocol ReusableView { /* only needed for providing behavior via extension */ }

public extension ReusableView where Self: UIView {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UITableViewCell: ReusableView { }
extension UITableViewHeaderFooterView: ReusableView { }
extension UICollectionViewCell: ReusableView { }

// MARK: NibLoadableView
public protocol NibLoadableView { /* only needed for providing behavior via extension */ }

public extension NibLoadableView where Self: UIView {
    static var nibName: String {
        return String(describing: self)
    }
}

extension UITableViewCell: NibLoadableView { }
extension UITableViewHeaderFooterView: NibLoadableView { }
extension UICollectionViewCell: NibLoadableView { }

// MARK: Functionality
public extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }

        return cell
    }

    func dequeueReusableCell<T: UITableViewCell>() -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }

        return cell
    }

    func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>() -> T {
        guard let view = dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as? T else {
            fatalError("Could not dequeue header or footer view with identifier: \(T.reuseIdentifier)")
        }

        return view
    }
}

public extension UITableView {
    func register<T: UITableViewCell>(_: T.Type, bundle: Bundle? = nil) {
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        register(nib, forCellReuseIdentifier: T.reuseIdentifier)
    }

    func register<T: UITableViewHeaderFooterView>(_: T.Type, bundle: Bundle? = nil) {
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        register(nib, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }
}

public extension UICollectionView {
    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }

        return cell
    }
}

public extension UICollectionView {
    func register<T: UICollectionViewCell>(_: T.Type, bundle: Bundle? = nil) {
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        register(nib, forCellWithReuseIdentifier: T.reuseIdentifier)
    }
}
