//
//  Created by Andreas Braun on 01.11.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import UIKit

class InformationTableViewController: UITableViewController {
    enum Category: String {
        case privacy
        case about
        case terms

        var title: String {
            switch self {
            case .privacy:
                return "Privacy policy"
            case .about:
                return "About Bunpro"
            case .terms:
                return "Terms of Service"
            }
        }

        var content: [Paragraph] {
            loadData(self)
        }

        private func loadData(_ category: Category) -> [Paragraph] {
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

    var category: InformationTableViewController.Category = .privacy {
        didSet {
            content = category.content
            title = category.title
        }
    }
    private var content: [Paragraph] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))

        content = category.content
        title = category.title
    }

    @IBAction private func close() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        content.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as UITableViewCell

        let paragraph = content[indexPath.row]

        cell.textLabel?.text = paragraph.headline
        cell.detailTextLabel?.text = paragraph.content

        return cell
    }
}
