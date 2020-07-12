//
//  Created by Andreas Braun on 05.11.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

#if canImport(Combine)
import Combine
#endif
import BunProKit
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
        StatusObserverImplementationCombine()
    }
}

private class StatusObserverImplementationCombine: StatusObserverProtocol {
    private var cancellables: Set<AnyCancellable> = []

    var didLogout: (() -> Void)? {
        didSet {
            NotificationCenter
                .default
                .publisher(for: Server.didLogoutNotification)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.didLogout?() }
                .store(in: &cancellables)
        }
    }

    var willBeginUpdating: (() -> Void)? {
        didSet {
            NotificationCenter
                .default
                .publisher(for: DataManager.willBeginUpdating)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.willBeginUpdating?() }
                .store(in: &cancellables)
        }
    }

    var didEndUpdating: (() -> Void)? {
        didSet {
            NotificationCenter
                .default
                .publisher(for: DataManager.didEndUpdating)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.didEndUpdating?() }
                .store(in: &cancellables)
        }
    }
    var didUpdateReview: (() -> Void)? {
        didSet {
            NotificationCenter
                .default
                .publisher(for: DataManager.didModifyReview)
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
                    name: Server.didLogoutNotification,
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
                    name: DataManager.willBeginUpdating,
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
                    name: DataManager.didEndUpdating,
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
                    name: DataManager.didModifyReview,
                    object: nil,
                    queue: OperationQueue.main) { [weak self] _ in
                        self?.didUpdateReview?()
                }
        }
    }
}
