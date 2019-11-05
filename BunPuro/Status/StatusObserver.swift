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
    private init() { }

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

    init() {
        logoutCancellable = NotificationCenter
            .default
            .publisher(for: .ServerDidLogoutNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.didLogout?()
            }

        beginUpdateCancellable = NotificationCenter
            .default
            .publisher(for: .BunProWillBeginUpdating)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.willBeginUpdating?()
            }

        endUpdateCancellable = NotificationCenter
            .default
            .publisher(for: .BunProDidEndUpdating)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.didEndUpdating?()
            }

        pendingModificationCancellable = NotificationCenter
            .default
            .publisher(for: .BunProDidModifyReview)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.didUpdateReview?()
            }
    }

    var didLogout: (() -> Void)?
    var willBeginUpdating: (() -> Void)?
    var didEndUpdating: (() -> Void)?
    var didUpdateReview: (() -> Void)?
}

private class StatusObserverIplementationNotificationCenter: StatusObserverProtocol {
    private var logoutObserver: NotificationToken?
    private var beginUpdateObserver: NotificationToken?
    private var endUpdateObserver: NotificationToken?
    private var pendingModificationObserver: NotificationToken?

    deinit {
        [logoutObserver,
         beginUpdateObserver,
         endUpdateObserver,
         pendingModificationObserver]
            .compactMap { $0 }
            .forEach { NotificationCenter.default.removeObserver($0) }
    }

    init() {
        logoutObserver = NotificationCenter.default.observe(name: .ServerDidLogoutNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.didLogout?()
        }

        beginUpdateObserver = NotificationCenter.default.observe(name: .BunProWillBeginUpdating, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.willBeginUpdating?()
        }

        endUpdateObserver = NotificationCenter.default.observe(name: .BunProDidEndUpdating, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.didEndUpdating?()
        }

        pendingModificationObserver = NotificationCenter.default.observe(name: .BunProDidModifyReview, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.didUpdateReview?()
        }
    }

    var didLogout: (() -> Void)?
    var willBeginUpdating: (() -> Void)?
    var didEndUpdating: (() -> Void)?
    var didUpdateReview: (() -> Void)?
}
