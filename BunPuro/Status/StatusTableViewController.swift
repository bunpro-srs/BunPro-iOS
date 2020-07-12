//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import ProcedureKit
import Protocols
import SafariServices
import UIKit

private let updateInterval = TimeInterval(60)

final class StatusTableViewController: UITableViewController {
    var showReviewsOnViewDidAppear: Bool = false

    private var statusObserver: StatusObserverProtocol?

    private var nextReviewDate: Date?
    private var reviews: [Review]?

    private let fetchedResultsController = StatusFetchedResultsController()

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: .ellipsisCircle, style: .done, target: self, action: #selector(presentSettingsViewController(_:)))
        ]

        statusObserver = StatusObserver.newObserver()

        statusObserver?.didLogout = { [weak self] in
            self?.setup(account: nil)
            self?.setup(reviews: nil)
        }

        statusObserver?.willBeginUpdating = { [weak self] in
            self?.statusCell()?.isUpdating = true
        }

        statusObserver?.didEndUpdating = { [weak self] in
            guard let `self` = self else { return }

            self.statusCell()?.isUpdating = false
            self.refreshControl?.endRefreshing()

            guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows?.filter({ $0.section == 1 }) else { return }

            visibleIndexPaths.forEach {
                guard let cell = self.tableView.cellForRow(at: $0) as? JLPTProgressTableViewCell else { return }

                let level = 5 - $0.row
                let metric = self.fetchedResultsController.metricForLevel(level)

                self.updateJLPTCell(cell, level: level, metric: metric)
            }
        }

        statusObserver?.didUpdateReview = { [weak self] in
            self?.tableView.reloadSections(IndexSet(integer: 1), with: .none)
        }

        fetchedResultsController.delegate = self
        fetchedResultsController.setup()

        setupKeyCommands()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        becomeFirstResponder()

        if showReviewsOnViewDidAppear {
            showReviewsOnViewDidAppear = false
            presentReviewViewController()
        }
    }

    private func statusCell() -> StatusTableViewCell? {
        let indexPath = IndexPath(row: 0, section: 0)
        return tableView.cellForRow(at: indexPath) as? StatusTableViewCell
    }

    @IBAction private func refresh(_ sender: UIRefreshControl) {
        AppDelegate.setNeedsStatusUpdate()
    }

    @IBAction private func presentSettingsViewController(_ sender: UIBarButtonItem) {
        let settingsViewCtrl = StoryboardScene.Settings.settingsTableViewController.instantiate()

        settingsViewCtrl.modalPresentationStyle = .popover
        settingsViewCtrl.popoverPresentationController?.barButtonItem = sender
        settingsViewCtrl.presentationController?.delegate = self

        present(settingsViewCtrl, animated: true, completion: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if AppDelegate.isContentAccessable {
                return 3 // Review, Cram and Study
            } else {
                return 0
            }

        default:
            return 5
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                if AppDelegate.isContentAccessable {
                    let cell = tableView.dequeueReusableCell(for: indexPath) as StatusTableViewCell
                    updateStatusCell(cell)

                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(for: indexPath) as SignUpTableViewCell

                    cell.titleLabel.text = L10n.Status.loading
                    cell.titleLabel.textColor = .white

                    return cell
                }

            case 1:
                let cell = tableView.dequeueReusableCell(for: indexPath) as SignUpTableViewCell
                cell.titleLabel.text = L10n.Status.cram
                return cell

            default:
                let cell = tableView.dequeueReusableCell(for: indexPath) as SignUpTableViewCell
                cell.titleLabel.text = L10n.Status.study
                return cell
            }

        default:
            let cell = tableView.dequeueReusableCell(for: indexPath) as JLPTProgressTableViewCell

            let level = 5 - indexPath.row
            let metric = fetchedResultsController.metricForLevel(5 - indexPath.row)

            updateJLPTCell(cell, level: level, metric: metric)

            return cell
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0, 1, 2:
                return indexPath

            default:
                return nil
            }

        default:
            return indexPath
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                presentReviewViewControllerIfPossible()

            case 1:
                presentCramViewController()

            case 2:
                presentStudyViewController()

            default:
                break
            }

        default:
            break
        }
    }

    @objc
    private func presentReviewViewControllerIfPossible() {
        if AppDelegate.isContentAccessable {
            if let nextReviewDate = nextReviewDate, nextReviewDate < Date() {
                presentReviewViewController()
            } else {
                presentReviewViewController(website: .main)
            }
        }
    }

    @objc
    private func presentCramViewController() {
        presentReviewViewController(website: .cram)
    }

    @objc
    private func presentStudyViewController() {
        presentReviewViewController(website: .study)
    }

    func presentReviewViewController(website: Website = .review) {
        let reviewProcedure = WebsiteViewControllerProcedure(presentingViewController: tabBarController!, website: website)

        reviewProcedure.openGrammarHandler = { viewController, identifier in
            let request: NSFetchRequest<Grammar> = Grammar.fetchRequest()
            request.predicate = NSPredicate(format: "%K == %d", #keyPath(Grammar.identifier), identifier)
            request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Grammar.identifier), ascending: true)]

            if let grammar = try? AppDelegate.database.viewContext.fetch(request).first {
                let grammarViewCtrl = StoryboardScene.GrammarDetail.grammarTableViewController.instantiate()
                grammarViewCtrl.grammar = grammar

                let navigationCtrl = UINavigationController(rootViewController: grammarViewCtrl)

                grammarViewCtrl.navigationItem.rightBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .done,
                    target: grammarViewCtrl,
                    action: #selector(GrammarTableViewController.dismissSelf)
                )

                viewController.present(navigationCtrl, animated: true, completion: nil)
            }
        }

        reviewProcedure.completionBlock = {
            DispatchQueue.main.async {
                AppDelegate.setNeedsStatusUpdate()
            }
        }

        switch website {
        case .study:
            reviewProcedure.userActivity = NSUserActivity.studyActivity

        case .cram:
            reviewProcedure.userActivity = NSUserActivity.cramActivity

        default:
            break
        }

        Server.add(procedure: reviewProcedure)
    }

    private func setup(account: Account?) {
        navigationItem.title = L10n.Tabbar.status
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }

    private var lastUpdateDate: Date?

    private func setup(reviews: [Review]?) {
        let reviewDate = reviews?.nextReviewDate
        if let reviewDate = reviewDate, self.nextReviewDate != reviewDate {
            UserNotificationCenter.shared.scheduleNextReviewNotification(at: reviewDate, reviewCount: reviews?.count ?? 0)
        }

        self.nextReviewDate = reviewDate

        self.reviews = reviews
        self.lastUpdateDate = Date()

        DispatchQueue.main.async {
            if let cell = self.statusCell() {
                self.updateStatusCell(cell)
            }

            AppDelegate.updateAppBadgeIcon()
        }
    }

    private func updateStatusCell(_ cell: StatusTableViewCell) {
        if let date = nextReviewDate {
            if date < Date() {
                cell.nextReviewsCount = AppDelegate.badgeNumber()?.intValue ?? 0
            } else {
                cell.nextReviewsCount = AppDelegate.badgeNumber(date: date)?.intValue ?? 0
            }
        } else {
            cell.nextReviewsCount = 0
        }

        cell.nextReviewDate = nextReviewDate

        cell.nextHourReviewCount = reviews?.reviewsWithinNextHour
        cell.nextDayReviewCount = reviews?.reviewsWithNext24Hours
        cell.lastUpdateDate = lastUpdateDate
    }

    private typealias JLPTCellMetric = (complete: Int, max: Int, progress: Float)

    private func updateJLPTCell(_ cell: JLPTProgressTableViewCell, level: Int, metric: JLPTCellMetric) {
        cell.title = "N\(level)"
        cell.subtitle = "\(metric.complete) / \(metric.max)"
        cell.setProgress(metric.progress, animated: false)
    }
}

extension StatusTableViewController: SegueHandler {
    enum SegueIdentifier: String {
        case showJLPT
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) else { return }

        switch segueIdentifier(for: segue) {
        case .showJLPT:
            let level = 5 - indexPath.row

            let destination = segue.destination.content as? SearchTableViewController
            destination?.sectionMode = .byLevel(level)
            destination?.title = "N\(level)"
        }
    }
}

extension StatusTableViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true, completion: nil)
    }
}

extension StatusTableViewController: StatusFetchedResultsControllerDelegate {
    func fetchedResultsAccountDidChange(account: Account?) {
        account?.managedObjectContext?.perform { [weak self] in
            self?.setup(account: account)
        }
    }

    func fetchedResultsReviewsDidChange(reviews: [Review]?) {
        reviews?.first?.managedObjectContext?.perform { [weak self] in
            self?.setup(reviews: reviews)
        }
    }
}

extension StatusTableViewController {

    private func setupKeyCommands() {
        addKeyCommand(
            UIKeyCommand(
                title: "Review",
                action: #selector(presentReviewViewControllerIfPossible),
                input: "R",
                modifierFlags: .command,
                state: AppDelegate.isContentAccessable ? .on : .off
            )
        )

        addKeyCommand(
            UIKeyCommand(
                title: "Cram",
                action: #selector(presentCramViewController),
                input: "C",
                modifierFlags: .command,
                state: AppDelegate.isContentAccessable ? .on : .off
            )
            )

        addKeyCommand(
            UIKeyCommand(
                title: "Study",
                action: #selector(presentStudyViewController),
                input: "S",
                modifierFlags: .command,
                state: AppDelegate.isContentAccessable ? .on : .off
            )
        )
    }
}

extension StatusTableViewController: UIAdaptivePresentationControllerDelegate {
    func presentationController(
        _ controller: UIPresentationController,
        viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle
    ) -> UIViewController? {
        let navigationController = UINavigationController(rootViewController: controller.presentedViewController)
        navigationController.navigationBar.prefersLargeTitles = true

        controller.presentedViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeSettingsViewController))

        return navigationController
    }

    @objc
    private func closeSettingsViewController() {
        dismiss(animated: true, completion: nil)
    }
}
