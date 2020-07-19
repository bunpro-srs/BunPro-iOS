//
//  Created by Andreas Braun on 17.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import BunProKit
import Combine
import CoreData
import Foundation
import SafariServices
import UIKit

final class DataManager {
    let presentingViewController: UIViewController
    let database: Database

    private var subscriptions = Set<AnyCancellable>()

    init(presentingViewController: UIViewController, database: Database) {
        self.presentingViewController = presentingViewController
        self.database = database

        let notificationCenter = NotificationCenter.default

        notificationCenter
            .publisher(for: Server.didLoginNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateGrammarDatabase()
            }
            .store(in: &subscriptions)

        notificationCenter
            .publisher(for: Server.didLogoutNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.database.resetAccount()
                self?.database.resetReviews()
                self?.scheduleUpdateProcedure()
            }
            .store(in: &subscriptions)

        notificationCenter
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.stopStatusUpdates()
                self?.isUpdating = false
            }
            .store(in: &subscriptions)
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
        let addProcedure = ModifyReviewProcedure(presentingViewController: presentingViewController, modificationType: modificationType) { result in
            switch result {
            case let .failure(error):
                log.error(error)
            case .success:
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

        let statusProcedure = StatusProcedure(presentingViewController: presentingViewController) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .failure(error):
                log.debug(error)
            case let .success((account, reviews)):
                self.database.updateAccount(account) { }
                
                DispatchQueue.main.async { [weak self] in
                    if !reviews.isEmpty {
                        let oldReviewsCount = AppDelegate.badgeNumber()?.intValue ?? 0

                        self?.database.updateReviews(reviews) { [weak self] in
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
                    } else {
                        self?.isUpdating = false
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
