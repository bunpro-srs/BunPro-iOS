//
//  Created by Andreas Braun on 24.07.20.
//  Copyright © 2020 Andreas Braun. All rights reserved.
//

import Combine
import Foundation

final class InformationStore: ObservableObject {
    @Published private(set) var category: InformationView.Category
    @Published private(set) var paragraphes: [Paragraph] = []

    init(category: InformationView.Category) {
        self.category = category
        self.updateParagraphs()
    }

    private func updateParagraphs() {
        paragraphes = paragraphes(for: category)
    }

    private func paragraphes(for category: InformationView.Category) -> [Paragraph] {
        guard let url = Bundle.main.url(forResource: category.rawValue, withExtension: "json") else {
            fatalError("Unable to load resource \(category.rawValue)")
        }

        do {
            let data = try Data(contentsOf: url)

            return try JSONDecoder().decode([Paragraph].self, from: data)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
