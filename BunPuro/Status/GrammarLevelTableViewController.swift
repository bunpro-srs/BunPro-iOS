//
//  Created by Andreas Braun on 07.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import BunPuroKit
import CoreData
import UIKit

final class GrammarLevelTableViewController: CoreDataFetchedResultsTableViewController<Grammar>, SegueHandler {
    enum SegueIdentifier: String {
        case showGrammar
    }

    var level: Int = 5

    private var searchBarButtonItem: UIBarButtonItem!
    private var activityIndicatorView: UIActivityIndicatorView?

    private var willUpdateObserver: NSObjectProtocol?
    private var didUpdateObserver: NSObjectProtocol?

    deinit {
        log.info("deinit \(String(describing: self))")

        for observer in [willUpdateObserver, didUpdateObserver] {
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = Asset.background.color

        activityIndicatorView = UIActivityIndicatorView(style: .white)
        activityIndicatorView?.hidesWhenStopped = true

        searchBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: nil, action: nil)
        navigationItem.rightBarButtonItems = [/*searchBarButtonItem, */UIBarButtonItem(customView: activityIndicatorView!)]

        willUpdateObserver = NotificationCenter.default.addObserver(
            forName: .BunProWillBeginUpdating,
            object: nil,
            queue: OperationQueue.main) { [weak self] _ in
                self?.activityIndicatorView?.startAnimating()
        }

        didUpdateObserver = NotificationCenter.default.addObserver(
            forName: .BunProDidEndUpdating,
            object: nil,
            queue: OperationQueue.main) { [weak self] _ in
                self?.activityIndicatorView?.stopAnimating()
                self?.tableView.reloadData()
        }

        let request: NSFetchRequest<Grammar> = Grammar.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(Grammar.level), "JLPT\(level)")

        let levelSort = NSSortDescriptor(key: #keyPath(Grammar.level), ascending: false)
        let orderSort = NSSortDescriptor(key: #keyPath(Grammar.lessonIdentifier), ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
        let identifierSort = NSSortDescriptor(key: #keyPath(Grammar.identifier), ascending: true)

        request.sortDescriptors = [levelSort, orderSort, identifierSort]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
            sectionNameKeyPath: #keyPath(Grammar.lessonIdentifier),
            cacheName: nil
        )
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as GrammarTeaserCell

        let grammar = fetchedResultsController.object(at: indexPath)

        let hasReview = grammar.review?.complete == true

        cell.japaneseLabel?.text = grammar.title
        cell.meaningLabel?.text = grammar.meaning
        cell.isComplete = hasReview

        return cell
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard AppDelegate.isContentAccessable else { return nil }

        let point = fetchedResultsController.object(at: indexPath)
        let review = point.review
        let hasReview = review?.complete ?? false

        var actions = [UIContextualAction]()

        if hasReview {
            let removeReviewAction = UIContextualAction(
                style: .normal,
                title: NSLocalizedString("review.edit.remove.short", comment: "")
            ) { _, _, completion in
                AppDelegate.modifyReview(.remove(review!.identifier))
                completion(true)
            }

            removeReviewAction.backgroundColor = .red

            let resetReviewAction = UIContextualAction(style: .normal,
                                                       title: L10n.Review.Edit.Reset.short) { _, _, completion in
                                                        AppDelegate.modifyReview(.reset(review!.identifier))

                                                        completion(true)
            }

            resetReviewAction.backgroundColor = .purple

            actions.append(removeReviewAction)
            actions.append(resetReviewAction)
        } else {
            let addToReviewAction = UIContextualAction(
                style: UIContextualAction.Style.normal,
                title: L10n.Review.Edit.Add.short
            ) { _, _, completion in
                AppDelegate.modifyReview(.add(point.identifier))
                completion(true)
            }

            actions.append(addToReviewAction)
        }

        let configuration = UISwipeActionsConfiguration(actions: actions)

        return configuration
    }

    private func progress(count: Int, max: Int) -> Float {
        guard max > 0 else { return 0 }
        return Float(count) / Float(max)
    }

    private func correctLevel(_ level: Int) -> Int {
        let mod = level % 10
        return mod == 0 ? 10 : mod
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let name = fetchedResultsController?.sections?[section].name, let level = Int(name) else { return nil }
        let cell = tableView.dequeueReusableCell() as JLPTProgressTableViewCell

        let grammarPoints = fetchedResultsController.fetchedObjects?.filter({ $0.lessonIdentifier == name }) ?? []
        let grammarCount = grammarPoints.count
        let finishedGrammarCount = grammarPoints.filter { $0.review?.complete == true }.count

        cell.title = L10n.Level.number(correctLevel(level))
        cell.subtitle = "\(finishedGrammarCount) / \(grammarCount)"
        cell.setProgress(progress(count: finishedGrammarCount, max: grammarCount), animated: false)

        return cell.contentView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 66
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController?.sections?.compactMap { section in
            guard let level = Int(section.name) else { return nil }
            return "\(correctLevel(level))"
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showGrammar:
            guard let cell = sender as? UITableViewCell else { fatalError() }
            guard let indexPath = tableView.indexPath(for: cell) else { fatalError() }

            let controller = segue.destination.content as? GrammarViewController
            controller?.grammar = fetchedResultsController.object(at: indexPath)
        }
    }
}
