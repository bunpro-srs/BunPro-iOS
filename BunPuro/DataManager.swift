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
    private var backgroundObserver: NotificationToken?

    deinit {
        if loginObserver != nil {
            NotificationCenter.default.removeObserver(loginObserver!)
        }

        if logoutObserver != nil {
            NotificationCenter.default.removeObserver(logoutObserver!)
        }

        if backgroundObserver != nil {
            NotificationCenter.default.removeObserver(backgroundObserver!)
        }
    }

    init(presentingViewController: UIViewController, database: Database) {
        self.presentingViewController = presentingViewController
        self.database = database

        loginObserver = NotificationCenter.default.observe(name: Server.didLoginNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.updateGrammarDatabase()
        }

        logoutObserver = NotificationCenter.default.observe(name: Server.didLogoutNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.database.resetReviews()
                self?.scheduleUpdateProcedure()
            }
        }

        backgroundObserver = NotificationCenter.default.observe(name: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.stopStatusUpdates()
            self?.isUpdating = false
        }
    }

    // Status Updates
    private let updateTimeInterval = TimeInterval(60 * 5)
    private var startImmediately: Bool = true
    var isUpdating: Bool = false {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: self.isUpdating ? DataManager.willBeginUpdating : DataManager.didEndUpdating, object: self)
            }
        }
    }
    private var statusUpdateTimer: Timer? { didSet { statusUpdateTimer?.tolerance = 10.0 } }

    private var hasPendingReviewModification: Bool = false

    func startStatusUpdates() {
        if startImmediately {
            startImmediately = false
            scheduleUpdateProcedure()
        }

        guard !isUpdating else { return }

        stopStatusUpdates()

        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: updateTimeInterval, repeats: true) { _ in
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

        let statusProcedure = StatusProcedure(presentingViewController: presentingViewController) { [weak self] user, reviews, _ in
            guard let self = self else { return }

            if let user = user {
                self.database.updateAccount(user) {
                    DispatchQueue.main.async { [weak self] in
                        self?.isUpdating = false
                    }
                }
            }

            DispatchQueue.main.async {
                if let reviews = reviews {
                    let oldReviewsCount = AppDelegate.badgeNumber()?.intValue ?? 0

                    self.database.updateReviews(reviews) { [weak self] in
                        guard let self = self else { return }

                        self.isUpdating = false

                        self.startStatusUpdates()

                        if self.hasPendingReviewModification {
                            self.hasPendingReviewModification = false
                            NotificationCenter.default.post(name: DataManager.didModifyReview, object: nil)
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

extension DataManager {
    static let willBeginUpdating = Notification.Name(rawValue: "DataManager.willBeginUpdating")
    static let didEndUpdating = Notification.Name(rawValue: "DataManager.didEndUpdating")
}

extension DataManager {
    static let didModifyReview = Notification.Name(rawValue: "DataManager.didModifyReview")
}
