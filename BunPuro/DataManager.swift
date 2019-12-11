//
//  Created by Andreas Braun on 17.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import Foundation
import SafariServices
import UIKit

final class DataManager {
    let presentingViewController: UIViewController
    let database: Database

    private var loginObserver: NotificationToken?
    private var logoutObserver: NotificationToken?

    deinit {
        if loginObserver != nil {
            NotificationCenter.default.removeObserver(loginObserver!)
        }

        if logoutObserver != nil {
            NotificationCenter.default.removeObserver(logoutObserver!)
        }
    }

    init(presentingViewController: UIViewController, database: Database) {
        self.presentingViewController = presentingViewController
        self.database = database

        loginObserver = NotificationCenter.default.observe(name: .ServerDidLoginNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.updateGrammarDatabase()
        }

        logoutObserver = NotificationCenter.default.observe(name: .ServerDidLogoutNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.database.resetReviews()
                self?.scheduleUpdateProcedure()
            }
        }
    }

    // Status Updates
    private let updateTimeInterval = TimeInterval(60 * 5)
    private var startImmediately: Bool = true
    var isUpdating: Bool = false {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: self.isUpdating ? .BunProWillBeginUpdating : .BunProDidEndUpdating, object: self)
            }
        }
    }
    private var statusUpdateTimer: Timer? { didSet { statusUpdateTimer?.tolerance = 10.0 } }

    private var hasPendingReviewModification: Bool = false

    func startStatusUpdates() {
        DispatchQueue.main.async {
            guard UIApplication.shared.applicationState == .active else { return }

            if self.startImmediately {
                self.startImmediately = false
                self.scheduleUpdateProcedure()
            }

            guard !self.isUpdating else { return }

            self.stopStatusUpdates()

            self.statusUpdateTimer = Timer(timeInterval: self.updateTimeInterval, repeats: true) { _ in
                guard !self.isUpdating else { return }
                self.scheduleUpdateProcedure()
            }

            RunLoop.main.add(self.statusUpdateTimer!, forMode: RunLoop.Mode.default)
        }
    }

    func stopStatusUpdates() {
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
    }

    func immidiateStatusUpdate() {
        self.scheduleUpdateProcedure()
    }

    private func needsGrammarDatabaseUpdate() -> Bool {
        let lastUpdate = Settings.lastDatabaseUpdate

        return Date().hours(from: lastUpdate) > 7 * 24
    }

    private func updateGrammarDatabase() {
        guard needsGrammarDatabaseUpdate() else { return }

        if #available(iOS 13.0, *) {
            let updateProcedure = GrammarPointsProcedure(presentingViewController: presentingViewController)
            updateProcedure.addDidFinishBlockObserver { procedure, error in
                if let error = error {
                    log.error(error.localizedDescription)
                } else if let grammar = procedure.output.value?.value {
                    self.database.updateGrammar(grammar) {
                        Settings.lastDatabaseUpdate = Date()
                    }
                }
            }

            Server.add(procedure: updateProcedure)
        } else {
            let updateProcedure = UpdateGrammarProcedure(presentingViewController: presentingViewController)
            updateProcedure.addDidFinishBlockObserver { _, error in
                if error == nil {
                    Settings.lastDatabaseUpdate = Date()
                }
            }

            Server.add(procedure: updateProcedure)
        }
    }

    func modifyReview(_ modificationType: ModifyReviewProcedure.ModificationType) {
        let addProcedure = ModifyReviewProcedure(presentingViewController: presentingViewController, modificationType: modificationType) { error in
            log.error(error ?? "No Error")

            if error == nil {
                DispatchQueue.main.async {
                    self.hasPendingReviewModification = true
                    AppDelegate.setNeedsStatusUpdate()
                }
            }
        }

        Server.add(procedure: addProcedure)
    }

    func scheduleUpdateProcedure(completion: ((UIBackgroundFetchResult) -> Void)? = nil) {
        self.isUpdating = true

        let statusProcedure = StatusProcedure(presentingViewController: presentingViewController) { user, reviews, _ in
            if let user = user {
                self.database.updateAccount(user) {
                    DispatchQueue.main.async {
                        self.isUpdating = false
                    }
                }
            }

            DispatchQueue.main.async {
                if let reviews = reviews {
                    let oldReviewsCount = AppDelegate.badgeNumber()?.intValue ?? 0

                    self.database.updateReviews(reviews) {
                        self.isUpdating = false

                        self.startStatusUpdates()

                        if self.hasPendingReviewModification {
                            self.hasPendingReviewModification = false
                            NotificationCenter.default.post(name: .BunProDidModifyReview, object: nil)
                        }

                        DispatchQueue.main.async {
                            let newReviewsCount = AppDelegate.badgeNumber()?.intValue ?? 0
                            let hasNewReviews = newReviewsCount > oldReviewsCount
                            if hasNewReviews {
                                UserNotificationCenter.shared.scheduleNextReviewNotification(
                                    at: Date().addingTimeInterval(1.0),
                                    reviewCount: newReviewsCount - oldReviewsCount
                                )
                            }

                            completion?(hasNewReviews ? .newData : .noData)
                        }
                    }
                }
            }
        }

        Server.add(procedure: statusProcedure)
    }
}

extension Notification.Name {
    static let BunProWillBeginUpdating = Notification.Name(rawValue: "BunProWillBeginUpdating")
    static let BunProDidEndUpdating = Notification.Name(rawValue: "BunProDidEndUpdating")
}

extension Notification.Name {
    static let BunProDidModifyReview = Notification.Name(rawValue: "BunProDidModifyReview")
}
