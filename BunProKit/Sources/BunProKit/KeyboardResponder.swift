//
//  KeyboardResponder.swift
//  
//
//  Created by Andreas Braun on 12.07.20.
//

import Combine
import SwiftUI

final class KeyboardResponder: ObservableObject {
    private var notificationCenter: NotificationCenter
    @Published private(set) var currentHeight: CGFloat = 0
    
    private var subscriptions = Set<AnyCancellable>()

    init(center: NotificationCenter = .default) {
        notificationCenter = center
        
        notificationCenter.publisher(for: UIResponder.keyboardWillShowNotification).sink(receiveValue: keyBoardWillShow(notification:)).store(in: &subscriptions)
        notificationCenter.publisher(for: UIResponder.keyboardWillHideNotification).sink(receiveValue: keyBoardWillHide(notification:)).store(in: &subscriptions)
    }

    func keyBoardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            currentHeight = keyboardSize.height
        }
    }

    func keyBoardWillHide(notification: Notification) {
        currentHeight = 0
    }
}
