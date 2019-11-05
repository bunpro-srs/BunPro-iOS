//
//  Created by Andreas Braun on 05.11.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Combine
import Foundation

protocol StatusObserverProtocol {
    var didLogout: (() -> Void)? { get set }
    var willBeginUpdating: (() -> Void)? { get set }
    var didEndUpdating: (() -> Void)? { get set }
    var didUpdateReview: (() -> Void)? { get set }
}

class StatusObserver {
    private init() {}

    static func newObserver() -> StatusObserverProtocol {
        if #available(iOS 13.0, *) {
            return StatusObserverImplementationCombine()
        } else {
            return StatusObserverIplementationNotificationCenter()
        }
    }
}

@available(iOS 13.0, *)
private class StatusObserverImplementationCombine: StatusObserverProtocol {
    private var logoutCancellable: AnyCancellable?
    private var beginUpdateCancellable: AnyCancellable?
    private var endUpdateCancellable: AnyCancellable?
    private var pendingModificationCancellable: AnyCancellable?

    var didLogout: (() -> Void)? {
        didSet {
            logoutCancellable?.cancel()

            logoutCancellable = NotificationCenter
                .default
                .publisher(for: .ServerDidLogoutNotification)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.didLogout?()
                }
        }
    }

    var willBeginUpdating: (() -> Void)? {
        didSet {
            beginUpdateCancellable?.cancel()

            beginUpdateCancellable = NotificationCenter
                .default
                .publisher(for: .BunProWillBeginUpdating)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.willBeginUpdating?()
                }
        }
    }

    var didEndUpdating: (() -> Void)? {
        didSet {
            endUpdateCancellable?.cancel()

            endUpdateCancellable = NotificationCenter
                .default
                .publisher(for: .BunProDidEndUpdating)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.didEndUpdating?()
                }
        }
    }
    var didUpdateReview: (() -> Void)? {
        didSet {
            pendingModificationCancellable?.cancel()

            pendingModificationCancellable = NotificationCenter
                .default
                .publisher(for: .BunProDidModifyReview)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.didUpdateReview?()
                }
        }
    }
}

private class StatusObserverIplementationNotificationCenter: StatusObserverProtocol {
    private var logoutObserver: NotificationToken?
    private var beginUpdateObserver: NotificationToken?
    private var endUpdateObserver: NotificationToken?
    private var pendingModificationObserver: NotificationToken?

    deinit {
        [logoutObserver, beginUpdateObserver, endUpdateObserver, pendingModificationObserver]
            .compactMap { $0 }
            .forEach { NotificationCenter.default.removeObserver($0) }
    }

    var didLogout: (() -> Void)? {
        didSet {
            logoutObserver = NotificationCenter
                .default.observe(
                    name: .ServerDidLogoutNotification,
                    object: nil,
                    queue: OperationQueue.main) { [weak self] _ in
                        self?.didLogout?()
                }
        }
    }

    var willBeginUpdating: (() -> Void)? {
        didSet {
            beginUpdateObserver = NotificationCenter
                .default
                .observe(
                    name: .BunProWillBeginUpdating,
                    object: nil,
                    queue: OperationQueue.main) { [weak self] _ in
                        self?.willBeginUpdating?()
                }
        }
    }
    var didEndUpdating: (() -> Void)? {
        didSet {
            endUpdateObserver = NotificationCenter
                .default
                .observe(
                    name: .BunProDidEndUpdating,
                    object: nil,
                    queue: OperationQueue.main) { [weak self] _ in
                        self?.didEndUpdating?()
                }
        }
    }
    var didUpdateReview: (() -> Void)? {
        didSet {
            pendingModificationObserver = NotificationCenter
                .default
                .observe(
                    name: .BunProDidModifyReview,
                    object: nil,
                    queue: OperationQueue.main) { [weak self] _ in
                        self?.didUpdateReview?()
                }
        }
    }
}
