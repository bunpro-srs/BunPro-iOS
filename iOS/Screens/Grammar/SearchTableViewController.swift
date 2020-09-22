//
//  Created by Andreas Braun on 29.11.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Combine
import UIKit

class SearchTableViewController: UITableViewController, UISearchBarDelegate {
    var sectionMode: SearchSectionMode = .byDifficulty {
        didSet {
            searchDataSource?.sectionMode = sectionMode
            if let searchController = searchController {
                updateSearchResults(for: searchController)
            }
            filterButton?.title = sectionMode.title
        }
    }

    private var filterButton: UIBarButtonItem!

    private var searchController: UISearchController!
    private var searchDataSource: SearchDataSource!

    private var subscriptions = Set<AnyCancellable>()

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = L10n.Tabbar.search

        setupFilterButton()
        setupNotifications()

        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self

        searchController.hidesNavigationBarDuringPresentation = true

        navigationItem.searchController = searchController
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        navigationItem.hidesSearchBarWhenScrolling = false

        searchController.searchBar.placeholder = L10n.Search.Grammar.placeholder

        searchController.searchBar.scopeButtonTitles = [
            L10n.Search.Grammar.Scope.all,
            L10n.Search.Grammar.Scope.unlearned,
            L10n.Search.Grammar.Scope.learned
        ]

        searchController.obscuresBackgroundDuringPresentation = false

        searchDataSource = DiffableSearchDataSource(tableView: tableView) { tableView, indexPath, _ in
            let grammar = self.searchDataSource.grammar(at: indexPath)
            let cell = tableView.dequeueReusableCell(for: indexPath) as GrammarTeaserCell

            cell.update(with: grammar)

            return cell
        }

        searchDataSource.sectionMode = sectionMode

        tableView.dataSource = searchDataSource

        setupKeyCommands()
    }

    private var didLoad: Bool = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        becomeFirstResponder()

        if !didLoad {
            didLoad.toggle()
            searchDataSource.performSearchQuery(scope: .all, searchText: nil)
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let name = searchDataSource.jlptLevel(for: section) else { return nil }
        let cell = tableView.dequeueReusableCell() as JLPTProgressTableViewCell

        switch searchDataSource.sectionMode {
        case .byDifficulty:
            cell.title = name.replacingOccurrences(of: "JLPT", with: "N")

        case .byLevel:
            cell.title = "Level \(searchDataSource.currentLevel(for: section))"
        }

        let grammarPoints = searchDataSource.grammar(for: name)
        let grammarCount = grammarPoints.count
        let finishedGrammarCount = grammarPoints.filter { $0.review?.complete == true }.count

        let scope = SearchScope(rawValue: searchController.searchBar.selectedScopeButtonIndex)!

        switch scope {
        case .all:
            cell.subtitle = "\(finishedGrammarCount) / \(grammarCount)"
            cell.setProgress(progress(count: finishedGrammarCount, max: grammarCount), animated: false)

        case .unlearned, .learned:
            cell.subtitle = "\(grammarCount)"
            cell.setProgress(0.0, animated: false)
        }

        return cell.contentView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        66
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        swipeActionsConfiguration(for: searchDataSource.grammar(at: indexPath))
    }

    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        contextMenuConfiguration(for: searchDataSource.grammar(at: indexPath))
    }

    private func setupFilterButton() {
        if #available(iOS 14.0, *) {
            var actions = [
                UIAction(title: L10n.Search.Grammar.Filter.Option.all) { [weak self] _ in
                    self?.sectionMode = .byDifficulty
                }
            ]

            for level in [5, 4, 3, 2, 1] {
                actions.append(
                    UIAction(title: L10n.Search.Grammar.Filter.Option.level(level)) { [weak self] _ in
                        self?.sectionMode = .byLevel(level)
                    }
                )
            }

            filterButton = UIBarButtonItem(
                title: "Filter",
                image: nil,
                primaryAction: nil,
                menu: UIMenu(
                    title: "",
                    image: nil,
                    identifier: nil,
                    options: .displayInline,
                    children: actions
                )
            )
        } else {
            filterButton = UIBarButtonItem(
                title: sectionMode.title,
                style: .plain,
                target: self,
                action: #selector(filterButtonPressed(sender:))
            )
        }

        filterButton.title = self.sectionMode.title

        navigationItem.rightBarButtonItem = filterButton
    }

    private func setupNotifications() {
        let notificationCenter = NotificationCenter.default

        notificationCenter
            .publisher(for: DataManager.willBeginUpdating)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                let activityIndicatorView: UIActivityIndicatorView

                activityIndicatorView = UIActivityIndicatorView(style: .medium)

                activityIndicatorView.startAnimating()

                self?.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicatorView)
            }
            .store(in: &subscriptions)

        notificationCenter
            .publisher(for: DataManager.didEndUpdating)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.navigationItem.rightBarButtonItem = self?.filterButton
            }
            .store(in: &subscriptions)

        notificationCenter
            .publisher(for: DataManager.didModifyReview)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.navigationItem.rightBarButtonItem = self?.filterButton
            }
            .store(in: &subscriptions)
    }

    private func progress(count: Int, max: Int) -> Float {
        guard max > 0 else { return 0 }
        return Float(count) / Float(max)
    }

    @IBSegueAction
    func showGrammar(_ coder: NSCoder, sender: Any?) -> UIViewController? {
        guard let cell = sender as? GrammarTeaserCell else {
            fatalError("sender should be an instance of GrammarTeaserCell")
        }
        guard let indexPath = tableView.indexPath(for: cell) else {
            fatalError("No indexPath for cell \(cell)")
        }

        let grammarViewCtrl = GrammarTableViewController(coder: coder)
        grammarViewCtrl?.grammar = searchDataSource.grammar(at: indexPath)
        return grammarViewCtrl
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showGrammar" else {
            fatalError("segue identifier should be showGrammar")
        }
        guard let cell = sender as? GrammarTeaserCell else {
            fatalError("sender should be an instance of GrammarTeaserCell")
        }
        guard let indexPath = tableView.indexPath(for: cell) else {
            fatalError("No indexPath for cell \(cell)")
        }

        let grammarViewCtrl = segue.destination.content as? GrammarTableViewController
        grammarViewCtrl?.grammar = searchDataSource.grammar(at: indexPath)
    }

    @IBAction private func filterButtonPressed(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = filterButton

        alertController.addAction(
            UIAlertAction(title: L10n.Search.Grammar.Filter.Option.all, style: .default) { [weak self] _ in
                self?.sectionMode = .byDifficulty
            }
        )

        for level in [5, 4, 3, 2, 1] {
            alertController.addAction(
                UIAlertAction(title: L10n.Search.Grammar.Filter.Option.level(level), style: .default) { [weak self] _ in
                    self?.sectionMode = .byLevel(level)
                }
            )
        }

        alertController.addAction(
            UIAlertAction(title: L10n.General.cancel, style: .cancel, handler: nil)
        )

        present(alertController, animated: true, completion: nil)
    }
}

extension SearchTableViewController: UISearchResultsUpdating {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        let scope = SearchScope(rawValue: selectedScope)!
        let searchText = searchBar.text

        searchDataSource.performSearchQuery(scope: scope, searchText: searchText)
    }

    func updateSearchResults(for searchController: UISearchController) {
        let scope = SearchScope(rawValue: searchController.searchBar.selectedScopeButtonIndex)!
        let searchText = searchController.searchBar.text

        searchDataSource.performSearchQuery(scope: scope, searchText: searchText)
    }
}

extension SearchTableViewController: TrailingSwipeActionsConfigurationProvider { }

extension SearchTableViewController {
    fileprivate func setupKeyCommands() {
        addKeyCommand(
            UIKeyCommand(
                title: "Show all grammar",
                action: #selector(toggleShowAllGrammar),
                input: "1",
                modifierFlags: .command
            )
        )

        addKeyCommand(
            UIKeyCommand(
                title: "Show unlearned grammar",
                action: #selector(toggleShowUnlearnedGrammar),
                input: "2",
                modifierFlags: .command
            )
        )

        addKeyCommand(
            UIKeyCommand(
                title: "Show learned grammar",
                action: #selector(toggleShowLearnedGrammar),
                input: "3",
                modifierFlags: .command
            )
        )
    }

    @objc
    private func toggleShowAllGrammar() {
        searchController.searchBar.selectedScopeButtonIndex = 0
        searchBar(searchController.searchBar, selectedScopeButtonIndexDidChange: searchController.searchBar.selectedScopeButtonIndex)
    }

    @objc
    private func toggleShowUnlearnedGrammar() {
        searchController.searchBar.selectedScopeButtonIndex = 1
        searchBar(searchController.searchBar, selectedScopeButtonIndexDidChange: searchController.searchBar.selectedScopeButtonIndex)
    }

    @objc
    private func toggleShowLearnedGrammar() {
        searchController.searchBar.selectedScopeButtonIndex = 2
        searchBar(searchController.searchBar, selectedScopeButtonIndexDidChange: searchController.searchBar.selectedScopeButtonIndex)
    }
}

private extension SearchSectionMode {
    var title: String {
        switch self {
        case .byDifficulty:
            return L10n.Search.Grammar.Filter.Title.all

        case let .byLevel(level):
            return L10n.Search.Grammar.Filter.Title.level(level)
        }
    }
}
