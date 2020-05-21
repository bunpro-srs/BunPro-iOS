//
//  Created by Andreas Braun on 19.02.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import Protocols
import UIKit

final class KanjiTableViewController: UITableViewController {
    var japanese: String?
    var english: String?
    var furigana = [Furigana]()

    var showEnglish: Bool = false

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2 // Japanese and English Translation
        }

        return furigana.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as DetailCell

        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.attributedName = japanese?
                    .htmlAttributedString(font: cell.textLabel?.font, color: .white)?
                    .string
            } else {
                cell.name = showEnglish ? english : L10n.Kanji.English.show
                if #available(iOS 13.0, *) {
                    cell.nameColor = showEnglish ? UIColor.label : view.tintColor
                } else {
                    cell.nameColor = showEnglish ? UIColor.black : view.tintColor
                }
            }
        } else {
            let info = furigana[indexPath.row]

            cell.name = "\(info.original)（\(info.text)）"
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section == 1, self.tableView(tableView, numberOfRowsInSection: section) > 0 else { return nil }

        return L10n.Kanji.Header.readings
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                showCopyJapaneseOrEnglish(at: indexPath)

            case 1:
                showEnglish.toggle()
                tableView.reloadData()

            default:
                break
            }

        default:
            showCopyKanjiOrKana(at: indexPath)
        }
    }

    private func showCopyJapaneseOrEnglish(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let copyKanjiOnly = UIAlertAction(title: L10n.Copy.japanese, style: .default) { [weak self] _ in
            UIPasteboard.general.string = self?.japanese?.htmlAttributedString?.string
        }

        let copyKana = UIAlertAction(title: L10n.Copy.english, style: .default) { [weak self] _ in
            UIPasteboard.general.string = self?.english?.htmlAttributedString?.string
        }

        alertController.addAction(copyKanjiOnly)
        alertController.addAction(copyKana)

        alertController.addAction(UIAlertAction(title: L10n.General.cancel, style: .cancel))

        alertController.popoverPresentationController?.sourceView = cell
        alertController.popoverPresentationController?.sourceRect = cell.bounds

        present(alertController, animated: true)
    }

    private func showCopyKanjiOrKana(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let copyKanjiOnly = UIAlertAction(title: L10n.Copy.kanji, style: .default) { [weak self] _ in
            UIPasteboard.general.string = self?.furigana[indexPath.row].original
        }

        let copyKana = UIAlertAction(title: L10n.Copy.kana, style: .default) { [weak self] _ in
            UIPasteboard.general.string = self?.furigana[indexPath.row].text
        }

        alertController.addAction(copyKanjiOnly)
        alertController.addAction(copyKana)

        alertController.addAction(UIAlertAction(title: L10n.General.cancel, style: .cancel))

        alertController.popoverPresentationController?.sourceView = cell
        alertController.popoverPresentationController?.sourceRect = cell.bounds

        present(alertController, animated: true)
    }
}
