//
//  Created by Andreas Braun on 05.11.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

#if canImport(Combine)
import Combine
#endif
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
    private var cancellables: Set<AnyCancellable> = []

    var didLogout: (() -> Void)? {
        didSet {
            NotificationCenter
                .default
                .publisher(for: .ServerDidLogoutNotification)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.didLogout?() }
                .store(in: &cancellables)
        }
    }

    var willBeginUpdating: (() -> Void)? {
        didSet {
            NotificationCenter
                .default
                .publisher(for: .BunProWillBeginUpdating)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.willBeginUpdating?() }
                .store(in: &cancellables)
        }
    }

    var didEndUpdating: (() -> Void)? {
        didSet {
            NotificationCenter
                .default
                .publisher(for: .BunProDidEndUpdating)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.didEndUpdating?() }
                .store(in: &cancellables)
        }
    }
    var didUpdateReview: (() -> Void)? {
        didSet {
            NotificationCenter
                .default
                .publisher(for: .BunProDidModifyReview)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.didUpdateReview?() }
                .store(in: &cancellables)
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
