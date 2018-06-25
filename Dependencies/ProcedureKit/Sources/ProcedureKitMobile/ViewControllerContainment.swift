//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
import ProcedureKit
import Foundation
import UIKit
#endif

/// A struct of the views which require autolayout constraints
public struct AutolayoutViews {
    let child: UIView
    let parent: UIView
}

/// A block type which receives the child's view to perform any autolayout.
public typealias SetAutolayoutConstraintsBlockType = (AutolayoutViews) -> ()

@available(iOS 9.0, *)
public enum SetAutolayoutConstraints {

    // Uses NSLayoutConstraint pinning the child to the parent's anchors.
    case pinnedToParent

    // Provide a custom block
    case custom(SetAutolayoutConstraintsBlockType)

    var block: SetAutolayoutConstraintsBlockType {
        switch self {
        case .pinnedToParent:
            return { views in
                NSLayoutConstraint.activate([
                    views.child.leadingAnchor.constraint(equalTo: views.parent.leadingAnchor),
                    views.child.trailingAnchor.constraint(equalTo: views.parent.trailingAnchor),
                    views.child.topAnchor.constraint(equalTo: views.parent.topAnchor),
                    views.child.bottomAnchor.constraint(equalTo: views.parent.bottomAnchor)
                ])
            }
        case let .custom(block):
            return block
        }
    }
}


internal extension UIViewController {

    func add(child: UIViewController, with frame: CGRect? = nil, in view: UIView, setAutolayoutConstraints block: @escaping SetAutolayoutConstraintsBlockType) {
        addChildViewController(child)
        child.view.frame = frame ?? CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        view.addSubview(child.view)
        block(AutolayoutViews(child: child.view, parent: view))
        child.didMove(toParentViewController: self)
    }

    func removeFromParent() {
        self.willMove(toParentViewController: nil)
        self.view.removeFromSuperview()
        self.removeFromParentViewController()
    }
}


/**
 Procedure to safely add a child view controller to a parent using
 UIViewController containment.
 */
open class AddChildViewControllerProcedure: UIBlockProcedure {

    public init(_ child: UIViewController, to parent: UIViewController, with frame: CGRect? = nil, in subview: UIView? = nil, setAutolayoutConstraints block: @escaping SetAutolayoutConstraintsBlockType) {
        let view: UIView = subview ?? parent.view
        assert(view.isDescendant(of: parent.view))
        super.init {
            parent.add(child: child, with: frame, in: view, setAutolayoutConstraints: block)
        }
        name = "Add Child ViewController"
    }

    @available(iOS 9.0, *)
    public convenience init(_ child: UIViewController, to parent: UIViewController, with frame: CGRect? = nil, in view: UIView, setAutolayoutConstraints strategy: SetAutolayoutConstraints = .pinnedToParent) {
        self.init(child, to: parent, with: frame, in: view, setAutolayoutConstraints: strategy.block)
    }
}

/**
 Procedure to safely remove a child view controller from its parent using
 UIViewController containment.
 */
open class RemoveChildViewControllerProcedure: UIBlockProcedure {

    public init(_ child: UIViewController) {
        super.init {
            child.removeFromParent()
        }
        name = "Remove Child ViewController"
    }
}

open class SetChildViewControllerProcedure: UIBlockProcedure {

    public init(_ child: UIViewController, in parent: UIViewController, with frame: CGRect? = nil, in subview: UIView? = nil, setAutolayoutConstraints block: @escaping SetAutolayoutConstraintsBlockType) {
        let view: UIView = subview ?? parent.view
        assert(view.isDescendant(of: parent.view))
        super.init {
            parent.childViewControllers.forEach { $0.removeFromParent() }
            parent.add(child: child, with: frame, in: view, setAutolayoutConstraints: block)
        }
        name = "Set Child ViewController"
    }

    @available(iOS 9.0, *)
    public convenience init(_ child: UIViewController, to parent: UIViewController, with frame: CGRect? = nil, in view: UIView, setAutolayoutConstraints strategy: SetAutolayoutConstraints = .pinnedToParent) {
        self.init(child, in: parent, with: frame, in: view, setAutolayoutConstraints: strategy.block)
    }
}


