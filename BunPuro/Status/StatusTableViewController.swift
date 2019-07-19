//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import BunPuroKit
import CoreData
import ProcedureKit
import SafariServices
import UIKit

private let updateInterval = TimeInterval(60)

final class StatusTableViewController: UITableViewController {
    var showReviewsOnViewDidAppear: Bool = false

    private var logoutObserver: NotificationToken?
    private var beginUpdateObserver: NotificationToken?
    private var endUpdateObserver: NotificationToken?
    private var pendingModificationObserver: NotificationToken?

    private var nextReviewDate: Date?
    private var reviews: [Review]?

    private let fetchedResultsController = StatusFetchedResultsController()

    override func viewDidLoad() {
        super.viewDidLoad()

        logoutObserver = NotificationCenter.default.observe(name: .ServerDidLogoutNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.setup(account: nil)
                self?.setup(reviews: nil)
            }
        }

        beginUpdateObserver = NotificationCenter.default.observe(name: .BunProWillBeginUpdating, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.statusCell()?.isUpdating = AppDelegate.isUpdating
            }
        }

        endUpdateObserver = NotificationCenter.default.observe(name: .BunProDidEndUpdating, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.statusCell()?.isUpdating = AppDelegate.isUpdating
                self.refreshControl?.endRefreshing()

                guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows?.filter({ $0.section == 1 }) else { return }

                visibleIndexPaths.forEach {
                    guard let cell = self.tableView.cellForRow(at: $0) as? JLPTProgressTableViewCell else { return }

                    let level = 5 - $0.row
                    let metric = self.fetchedResultsController.metricForLevel(level)

                    self.updateJLPTCell(cell, level: level, metric: metric)
                }
            }
        }

        pendingModificationObserver = NotificationCenter.default.observe(name: .BunProDidModifyReview, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.tableView.reloadSections(IndexSet(integer: 1), with: .none)
            }
        }

        fetchedResultsController.delegate = self
        fetchedResultsController.setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if AppDelegate.isContentAccessable {
                return 3 // Review, Cram and Study
            } else if AppDelegate.isTrialPeriodAvailable {
                return 1
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
                } else if AppDelegate.isTrialPeriodAvailable {
                    let cell = tableView.dequeueReusableCell(for: indexPath) as SignUpTableViewCell
                    cell.titleLabel.text = L10n.Status.signuptrail

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
                if AppDelegate.isContentAccessable {
                    if let nextReviewDate = nextReviewDate, nextReviewDate < Date() {
                        presentReviewViewController()
                    } else {
                        presentReviewViewController(website: .main)
                    }
                } else if AppDelegate.isTrialPeriodAvailable {
                    AppDelegate.signupForTrial()
                } else if Account.currentAccount != nil {
                    AppDelegate.signup()
                }

            case 1:
                presentReviewViewController(website: .cram)

            case 2:
                presentReviewViewController(website: .study)

            default:
                break
            }

        default:
            break
        }
    }

    func presentReviewViewController(website: Website = .review) {
        let reviewProcedure = WebsiteViewControllerProcedure(presentingViewController: tabBarController!, website: website)

        reviewProcedure.completionBlock = {
            DispatchQueue.main.async {
                AppDelegate.setNeedsStatusUpdate()
            }
        }

        if #available(iOS 12.0, *) {
            switch website {
            case .study:
                reviewProcedure.userActivity = NSUserActivity.studyActivity

            case .cram:
                reviewProcedure.userActivity = NSUserActivity.cramActivity

            default:
                break
            }
        }

        Server.add(procedure: reviewProcedure)
    }

    private func setup(account: Account?) {
        navigationItem.title = account?.name
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }

    private var lastUpdateDate: Date?

    private func setup(reviews: [Review]?) {
        if let reviewDate = reviews?.nextReviewDate, self.nextReviewDate != reviewDate {
            UserNotificationCenter.shared.scheduleNextReviewNotification(at: reviewDate, reviewCount: reviews?.count ?? 0)
        }

        DispatchQueue.default.async {
            self.nextReviewDate = reviews?.nextReviewDate

            self.reviews = reviews
            self.lastUpdateDate = Date()

            DispatchQueue.main.async {
                if let cell = self.statusCell() {
                    self.updateStatusCell(cell)
                }

                AppDelegate.updateAppBadgeIcon()
            }
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

            let destination = segue.destination.content as? GrammarLevelTableViewController
            destination?.level = level
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
        setup(account: account)
    }

    func fetchedResultsReviewsDidChange(reviews: [Review]?) {
        setup(reviews: reviews)
    }
}
