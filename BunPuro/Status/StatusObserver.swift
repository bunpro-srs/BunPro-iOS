//
//  Created by Andreas Braun on 05.11.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import Combine
import BunProKit
import Foundation

protocol StatusObserverProtocol {
    var didLogout: (() -> Void)? { get set }
    var willBeginUpdating: (() -> Void)? { get set }
    var didEndUpdating: (() -> Void)? { get set }
    var didUpdateReview: (() -> Void)? { get set }
}

class StatusObserver: StatusObserverProtocol {
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
