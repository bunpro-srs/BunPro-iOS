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

    private var logoutObserver: NSObjectProtocol?
    private var beginUpdateObserver: NSObjectProtocol?
    private var endUpdateObserver: NSObjectProtocol?
    private var pendingModificationObserver: NSObjectProtocol?

    private var nextReviewDate: Date?
    private var reviews: [Review]?

    private var userFetchedResultsController: NSFetchedResultsController<Account>?
    private var reviewsFetchedResultsController: NSFetchedResultsController<Review>?

    deinit {
        print("deinit \(String(describing: self))")

        for observer in [logoutObserver, beginUpdateObserver, endUpdateObserver, pendingModificationObserver] where observer != nil {
            NotificationCenter.default.removeObserver(observer!)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = UIColor(named: "ModernDark")

        logoutObserver = NotificationCenter.default.addObserver(forName: .ServerDidLogoutNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.setup(account: nil)
                self?.setup(reviews: nil)
            }
        }

        beginUpdateObserver = NotificationCenter.default.addObserver(forName: .BunProWillBeginUpdating, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.statusCell()?.isUpdating = AppDelegate.isUpdating
            }
        }

        endUpdateObserver = NotificationCenter.default.addObserver(forName: .BunProDidEndUpdating, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.statusCell()?.isUpdating = AppDelegate.isUpdating
                self.refreshControl?.endRefreshing()

                guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows?.filter({ $0.section == 1 }) else { return }

                visibleIndexPaths.forEach {
                    guard let cell = self.tableView.cellForRow(at: $0) as? JLPTProgressTableViewCell else { return }

                    let level = 5 - $0.row
                    let metric = self.metricForLevel(level)

                    self.updateJLPTCell(cell, level: level, metric: metric)
                }
            }
        }

        pendingModificationObserver = NotificationCenter.default.addObserver(forName: .BunProDidModifyReview, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.tableView.reloadSections(IndexSet(integer: 1), with: .none)
            }
        }

        setupUserFetchedResultsController()
        setupReviewsFetchedResultsController()
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

    private func setupUserFetchedResultsController() {
        let request: NSFetchRequest<Account> = Account.fetchRequest()

        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Account.name), ascending: true)]

        userFetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        userFetchedResultsController?.delegate = self

        do {
            try userFetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
    }

    private func setupReviewsFetchedResultsController() {
        let request: NSFetchRequest<Review> = Review.fetchRequest()

        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Review.updatedDate), ascending: true)]

        request.predicate = NSPredicate(format: "%K < %@ AND %K == true", #keyPath(Review.nextReviewDate), Date().tomorrow.tomorrow.nextMidnight as NSDate, #keyPath(Review.complete))

        reviewsFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AppDelegate.coreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

        reviewsFetchedResultsController?.delegate = self

        do {
            try reviewsFetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
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
            return 4 //jlptFetchedResultsController?.fetchedObjects?.count ?? 0
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

                    cell.titleLabel.text = NSLocalizedString("status.signuptrail", comment: "The title of the signup for trial button")

                    return cell
                }
//                else if Account.currentAccount != nil {
//                    let cell = tableView.dequeueReusableCell(for: indexPath) as SignUpTableViewCell
//
//                    cell.titleLabel.text = NSLocalizedString("status.signup", comment: "The title of the signup button")
//
//                    return cell
//                }
                else {
                    let cell = tableView.dequeueReusableCell(for: indexPath) as SignUpTableViewCell

                    cell.titleLabel.text = NSLocalizedString("status.loading", comment: "The title of the loading indicator")
                    cell.titleLabel.textColor = .white

                    return cell
                }

            case 1:
                let cell = tableView.dequeueReusableCell(for: indexPath) as SignUpTableViewCell

                cell.titleLabel.text = NSLocalizedString("status.cram", comment: "The title of the cram button")

                return cell

            default:
                let cell = tableView.dequeueReusableCell(for: indexPath) as SignUpTableViewCell

                cell.titleLabel.text = NSLocalizedString("status.study", comment: "The title of the study button")

                return cell
            }

        default:
            let cell = tableView.dequeueReusableCell(for: indexPath) as JLPTProgressTableViewCell

            let level = 5 - indexPath.row
            let metric = metricForLevel(5 - indexPath.row)

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
            default: return nil
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
                    signupForTrial()
                } else if Account.currentAccount != nil {
                    signup()
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

    private func metricForLevel(_ level: Int) -> (complete: Int, max: Int, progress: Float) {
        let completeFetchRequest: NSFetchRequest<Grammar> = Grammar.fetchRequest()
        completeFetchRequest.predicate = NSPredicate(format: "%K = %@", #keyPath(Grammar.level), "JLPT\(level)")

        do {
            let grammarPoints = try AppDelegate.coreDataStack.managedObjectContext.fetch(completeFetchRequest)

            let complete = grammarPoints.filter({ $0.review?.complete == true }).count
            let max = grammarPoints.count

            var progress: Float = 0.0

            if max > 0, max >= complete {
                progress = Float(complete) / Float(max)
            }

            return (complete, max, progress)
        } catch {
            return (0, 0, 0.0)
        }
    }

    private func signupForTrial() {
        AppDelegate.signupForTrial()
    }

    private func signup() {
        AppDelegate.signup()
    }

    private func setup(account: Account?) {
        navigationItem.title = account?.name ?? NSLocalizedString("Loading...", comment: "")

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

    private func updateJLPTCell(_ cell: JLPTProgressTableViewCell, level: Int, metric: (complete: Int, max: Int, progress: Float)) {
        cell.titleLabel.text = "N\(level)"
        cell.subtitleLabel.text = "\(metric.complete) / \(metric.max)"
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

extension StatusTableViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == userFetchedResultsController, let account = userFetchedResultsController?.fetchedObjects?.first {
            setup(account: account)
        } else if controller == reviewsFetchedResultsController {
            setup(reviews: reviewsFetchedResultsController?.fetchedObjects)
        }
    }
}

extension StatusTableViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true, completion: nil)
    }
}

extension Collection where Iterator.Element == Review {
    public var nextReviewDate: Date? {
        let allDates = filter { $0.complete }.compactMap { $0.nextReviewDate }

        let tmp = allDates.reduce(Date.distantFuture, { $0 < $1 ? $0 : $1 })
        return tmp == Date.distantPast ? nil: tmp
    }

    public func reviews(at date: Date) -> [Review] {
        let result = filter { $0.complete && $0.nextReviewDate!.minutes(from: date) <= 0 }
        return result
    }

    public var reviewsWithinNextHour: Int {
        let date = Date()
        let result = filter { $0.complete && $0.nextReviewDate!.minutes(from: date) < 60 }
        return result.count
    }

    public var reviewsWithNext24Hours: Int {
        let date = Date()
        let result = filter { $0.complete && $0.nextReviewDate!.hours(from: date) <= 23 }
        return result.count
    }
}

extension Date {
    func minutes(from date: Date) -> Int {
        return Calendar.autoupdatingCurrent.dateComponents([.minute], from: date, to: self).minute!
    }

    func hours(from date: Date) -> Int {
        return Calendar.autoupdatingCurrent.dateComponents([.hour], from: date, to: self).hour!
    }

    func isTomorrow() -> Bool {
        return Calendar.autoupdatingCurrent.isDateInTomorrow(self)
    }

    var tomorrow: Date {
        return Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: noon)!
    }

    var noon: Date {
        return Calendar.autoupdatingCurrent.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }

    var nextMidnight: Date {
        return Calendar.autoupdatingCurrent.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
}
