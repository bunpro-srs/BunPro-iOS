//
//  Created by Andreas Braun on 19.07.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import SwiftUI
import UIKit

struct CloseButton: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> some UIView {
        let button = UIButton(type: .close)
        button.addTarget(context.coordinator, action: #selector(Coordinator.performAction), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc
        func performAction() {
            action()
        }
    }
}
