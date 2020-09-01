//
//  Created by Andreas Braun on 19.07.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import SwiftUI

struct ActionButton: View {
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill()
                .layoutPriority(1)
                .foregroundColor(Color(UIColor.secondarySystemFill))
                .shadow(radius: 3)

            Text(label)
                .foregroundColor(.accentColor)
        }
        .frame(height: 46)
        .onTapGesture {
            action()
        }
    }
}
