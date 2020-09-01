//
//  Created by Andreas Braun on 19.07.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import SwiftUI
import UIKit

struct InformationView: View {
    enum Category: String {
        case privacy
        case about
        case terms

        var localizedTitle: LocalizedStringKey {
            switch self {
            case .privacy:
                return LocalizedStringKey.Information.Category.privacy

            case .about:
                return LocalizedStringKey.Information.Category.about

            case .terms:
                return LocalizedStringKey.Information.Category.terms
            }
        }
    }

    @ObservedObject private var store: InformationStore

    @Binding var isPresenting: Bool

    init(isPresenting: Binding<Bool>, category: Category) {
        _isPresenting = isPresenting
        self.store = InformationStore(category: category)
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(store.paragraphes) { paragraph in
                    ParagraphView(paragraph)
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(store.category.localizedTitle)
            .navigationBarItems(
                trailing:
                    CloseButton {
                        $isPresenting.wrappedValue = false
                    }
            )
        }
    }
}

private struct ParagraphView: View {
    let paragraph: Paragraph

    init(_ paragraph: Paragraph) {
        self.paragraph = paragraph
    }

    var body: some View {
        Section(header: Group {
            if let title = paragraph.headline {
                Text(title)
                    .font(.title)
            }
        }) {
            if let content = paragraph.content {
                Text(content)
            }

            if let bulletpoints = paragraph.bulletpoints {
                ForEach(bulletpoints, id: \.self) { point in
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "circle.fill")
                            .imageScale(.small)
                            .foregroundColor(.secondary)
                        Text(point)
                    }
                }
            }
        }
    }
}

struct InformationView_Previews: PreviewProvider {
    static var previews: some View {
        InformationView(isPresenting: .constant(true), category: .about)
    }
}
