//
//  GrammarTableViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 21.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import BunPuroKit

protocol GrammarPresenter {
    var grammar: Grammar? { get set }
}

class GrammarViewController: UIViewController, GrammarPresenter {

    enum ViewMode: Int {
        case meaning
        case examples
        case reading
        
        var numberOfItems: Int {
            switch self {
            case .meaning:
                return 4
            default:
                return 0
            }
        }
    }
    
    @IBOutlet private weak var viewModeSegmentedControl: UISegmentedControl!
    private var pageViewController: UIPageViewController!
    
    var grammar: Grammar?
    
    private var viewMode: ViewMode = .meaning {
        didSet {
            viewModeSegmentedControl?.selectedSegmentIndex = viewMode.rawValue
            
            let direction: UIPageViewControllerNavigationDirection = viewMode.rawValue > oldValue.rawValue ? .forward : .reverse
            pageViewController?.setViewControllers([viewControllers[viewMode.rawValue]], direction: direction, animated: true, completion: nil)
        }
    }
    private lazy var viewControllers: [UIViewController] = {
        
        return [
            self.viewController(for: .meaning),
            self.viewController(for: .examples),
            self.viewController(for: .reading)
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(grammar != nil)
        
        navigationItem.title = grammar?.title
    }

    @IBAction func viewModeChanged(_ sender: UISegmentedControl) {
        guard let newViewMode = ViewMode(rawValue: sender.selectedSegmentIndex) else {
            fatalError("ViewMode (\(sender.selectedSegmentIndex)) not supported.")
        }
        
        viewMode = newViewMode
    }
    
    private func viewController(for viewMode: ViewMode) -> UIViewController {
        var viewController: UIViewController & GrammarPresenter
        
        switch viewMode {
        case .meaning:
            viewController = storyboard!.instantiateViewController() as GrammarMeaningViewController
        case .examples:
            viewController = storyboard!.instantiateViewController() as GrammarExampleSentancesViewController
        case .reading:
            viewController = storyboard!.instantiateViewController() as GrammarReadingsViewControllerTableViewController
        }
        
        viewController.grammar = grammar
        
        return viewController
    }

}

extension GrammarViewController: SegueHandler {
    
    enum SegueIdentifier: String {
        case embedPageViewController
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segueIdentifier(for: segue) {
        case .embedPageViewController:
            let destination = segue.destination.content as? UIPageViewController
            destination?.delegate = self
            destination?.dataSource = self
            
            destination?.setViewControllers([viewControllers.first!], direction: .forward, animated: false, completion: nil)
            pageViewController = destination
        }
    }
}

extension GrammarViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.index(of: viewController), index > 0 else { return nil }
        
        return viewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = viewControllers.index(of: viewController), index < viewControllers.count - 1 else { return nil }
        
        return viewControllers[index + 1]
    }
}

extension GrammarViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let firstViewController = pageViewController.viewControllers?.first else { return }
        guard let index = viewControllers.index(of: firstViewController) else { return }
        guard let newViewMode = ViewMode(rawValue: index) else { return }
        
        if completed {
            viewMode = newViewMode
        }
    }
    
}
