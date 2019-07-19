//
//  Created by Andreas Braun on 21.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import AVFoundation
import BunPuroKit
import SafariServices
import UIKit

protocol GrammarPresenter {
    var grammar: Grammar? { get set }
}

final class GrammarTableViewController: UITableViewController, GrammarPresenter {
    enum ViewMode: Int {
        case examples
        case reading
    }

    @IBOutlet private var selectionSectionHeaderView: UIView!
    @IBOutlet private weak var viewModeSegmentedControl: UISegmentedControl!
    @IBOutlet private var reviewEditBarButtonItem: UIBarButtonItem!

    private var player: AVPlayer?
    private let fetchedResultsController = GrammarFetchedResultsController()
    private let flowController = GrammarFlowController()

    var grammar: Grammar?

    private var viewMode: ViewMode = .examples {
        didSet {
            viewModeSegmentedControl?.selectedSegmentIndex = viewMode.rawValue
            tableView.reloadData()
        }
    }

    private var beginUpdateObserver: NotificationToken?
    private var endUpdateObserver: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = Asset.background.color

        assert(grammar != nil)
        updateEditBarButtonState()

        beginUpdateObserver = NotificationCenter.default.observe(name: .BunProWillBeginUpdating, object: nil, queue: OperationQueue.main) { _ in
            let activityIndicator = UIActivityIndicatorView(style: .white)
            activityIndicator.startAnimating()
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        }

        endUpdateObserver = NotificationCenter.default.observe(name: .BunProDidEndUpdating, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) { [weak self] in
                self?.navigationItem.rightBarButtonItem = self?.reviewEditBarButtonItem

                if let numberOfRows = self?.tableView.numberOfRows(inSection: 0) {
                    let complete = self?.grammar?.review?.complete ?? false

                    switch (numberOfRows, complete) {
                    case (2, true), (3, false):
                        self?.tableView.reloadData()

                    case (3, true):
                        self?.tableView.reloadData()

                    default:
                        break
                    }

                    self?.updateEditBarButtonState()
                }
            }
        }

        fetchedResultsController.delegate = self
        fetchedResultsController.setup(grammar: grammar!)
    }

    @IBAction private func viewModeChanged(_ sender: UISegmentedControl) {
        guard let newViewMode = ViewMode(rawValue: sender.selectedSegmentIndex) else { fatalError("ViewMode (\(sender.selectedSegmentIndex)) not supported.") }
        viewMode = newViewMode
    }

    @IBAction private func editReviewButtonPressed(_ sender: UIBarButtonItem) {
        flowController.editReviewButtonPressed(grammar: grammar!, barButtonItem: sender, viewController: self)
    }

    private func updateEditBarButtonState() {
        reviewEditBarButtonItem?.title = grammar?.review?.complete == true ? L10n.Review.Edit.Button.removeReset : L10n.Review.Edit.Button.add
        reviewEditBarButtonItem.isEnabled = AppDelegate.isContentAccessable
    }

    private func playSound(forSentenceAt indexPath: IndexPath) {
        guard let url = fetchedResultsController.exampleSentence(at: indexPath).audioURL else { return }
        log.info("play url: \(url)")

        if player == nil {
            player = AVPlayer(url: url)
            player?.volume = 1.0
        } else {
            player?.pause()

            let item = AVPlayerItem(url: url)
            player?.replaceCurrentItem(with: item)
        }

        player?.play()
    }

    @IBAction private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }
        guard let cell = (recognizer.view as? UITableViewCell), let indexPath = tableView.indexPath(for: cell) else { return }

        switch indexPath.section {
        case 0:
            break

        default:
            switch viewMode {
            case .examples:
                showCopyJapaneseOrEnglish(at: indexPath)

            case .reading:
                break
            }
        }
    }

    private func showCopyJapaneseOrMeaning(at indexPath: IndexPath) {
        showCopyActionSheet(
            at: indexPath,
            actions: [
                UIAlertAction(title: L10n.Copy.japanese, style: .default) { [weak self] _ in
                    UIPasteboard.general.string = self?.grammar?.title
                },
                UIAlertAction(title: L10n.Copy.meaning, style: .default) { [weak self] _ in
                    UIPasteboard.general.string = self?.grammar?.meaning
                }
            ]
        )
    }

    private func showCopyJapaneseOrEnglish(at indexPath: IndexPath) {
        let correctIndexPath = IndexPath(row: indexPath.row, section: 0)
        let sentence = fetchedResultsController.exampleSentence(at: correctIndexPath)

        showCopyActionSheet(
            at: indexPath,
            actions: [
                UIAlertAction(title: L10n.Copy.japanese, style: .default) { _ in
                    UIPasteboard.general.string = sentence.japanese?.htmlAttributedString?.string.cleanStringAndFurigana.string
                },
                UIAlertAction(title: L10n.Copy.english, style: .default) { _ in
                    UIPasteboard.general.string = sentence.english?.htmlAttributedString?.string
                }
            ]
        )
    }

    private func showCopyActionSheet(at indexPath: IndexPath, actions: [UIAlertAction]) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        actions.forEach { alertController.addAction($0) }
        alertController.addAction(UIAlertAction(title: L10n.General.cancel, style: .cancel))

        alertController.popoverPresentationController?.sourceView = cell
        alertController.popoverPresentationController?.sourceRect = cell.bounds

        present(alertController, animated: true)
    }
}

// UITableViewDelegate + UITableViewDataSource Protocol Implementation
extension GrammarTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return grammar?.review?.complete == true ? 3 : 2

        default:
            switch viewMode {
            case .examples:
                let subscribed = AppDelegate.isContentAccessable
                let actualNumberOfObjects = fetchedResultsController.exampleSentencesCount()
                return subscribed ? actualNumberOfObjects : actualNumberOfObjects > 0 ? 1 : 0

            case .reading:
                return fetchedResultsController.readingsCount()
            }
        }
    }

    private enum Info: Int {
        case basic
        case structure
        case streak
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch Info(rawValue: indexPath.row)! {
            case .basic:
                return basicInfoCell(tableView, indexPath)

            case .structure:
                return structureInfoCell(tableView, indexPath)

            case .streak:
                return streakInfoCell(tableView, indexPath)
            }

        default:
            return detailCell(tableView, indexPath)
        }
    }

    private func basicInfoCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as BasicInfoCell

        cell.titleLabel.text = grammar?.title
        cell.meaningLabel.text = grammar?.meaning

        let englishFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 12))

        if
            let caution = grammar?.caution?.replacingOccurrences(of: "<span class='chui'>", with: "").replacingOccurrences(of: "</span>", with: ""),
            let attributed = "⚠️ \(caution)".htmlAttributedString(font: englishFont, color: .white),
            !caution.isEmpty
        {
            cell.cautionLabel.attributedText = attributed
        } else {
            cell.cautionLabel.attributedText = nil
            cell.cautionLabel.isHidden = true
        }

        cell.separatorInset = UIEdgeInsets(top: 0, left: 100_000, bottom: 0, right: 0)
        return cell
    }

    private func structureInfoCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as StructureInfoCell
        let englishFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 12))

        cell.attributedDescription = grammar?.structure?.replacingOccurrences(of: ", ", with: "</br>").htmlAttributedString(font: englishFont, color: .white)
        cell.separatorInset = UIEdgeInsets(top: 0, left: 100_000, bottom: 0, right: 0)

        return cell
    }

    private func streakInfoCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as StreakInfoCell
        cell.streak = Int(grammar?.review?.streak ?? 0)
        return cell
    }

    private func detailCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as DetailCell
        cell.longPressGestureRecognizer = nil

        switch viewMode {
        case .examples:
            let correctIndexPath = IndexPath(row: indexPath.row, section: 0)
            let sentence = fetchedResultsController.exampleSentence(at: correctIndexPath)

            let japaneseFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 15))
            let englishFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 12))

            cell.attributedName = sentence.japanese?.cleanStringAndFurigana.string.htmlAttributedString(font: japaneseFont, color: Asset.mainTint.color)
            cell.attributedDescriptionText = sentence.english?.htmlAttributedString(font: englishFont, color: .white)
            cell.actionImage = sentence.audioURL != nil ? #imageLiteral(resourceName: "play") : nil

            cell.customAction = { [weak self] _ in self?.playSound(forSentenceAt: correctIndexPath) }
            cell.isDescriptionLabelHidden = Account.currentAccount?.englishMode ?? false
            cell.selectionStyle = .none

            if cell.longPressGestureRecognizer == nil {
                cell.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
                cell.addGestureRecognizer(cell.longPressGestureRecognizer!)
            }

        case .reading:
            let correctIndexPath = IndexPath(row: indexPath.row, section: 0)
            let link = fetchedResultsController.reading(at: correctIndexPath)

            let font1 = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 12))
            let font2 = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 10))

            cell.attributedName = link.site?.htmlAttributedString(font: font1, color: Asset.mainTint.color)
            cell.attributedDescriptionText = link.about?.htmlAttributedString(font: font2, color: .white)
            cell.isDescriptionLabelHidden = false
            cell.customAction = nil
            cell.actionImage = nil

            cell.selectionStyle = .none
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch Info(rawValue: indexPath.row)! {
            case .basic, .structure:
                showCopyJapaneseOrMeaning(at: indexPath)

            case .streak:
                break
            }

        case 1:
            defer { tableView.deselectRow(at: indexPath, animated: true) }

            switch viewMode {
            case .reading:
                let correctIndexPath = IndexPath(row: indexPath.row, section: 0)
                guard let url = fetchedResultsController.reading(at: correctIndexPath).url else { return }

                let safariViewCtrl = SFSafariViewController(url: url)
                present(safariViewCtrl, animated: true, completion: nil)

            case .examples:
                let correctIndexPath = IndexPath(row: indexPath.row, section: 0)
                let sentence = fetchedResultsController.exampleSentence(at: correctIndexPath)

                if let japanese = sentence.japanese?.cleanStringAndFurigana {
                    let infoViewCtrl = storyboard!.instantiateViewController() as KanjiTableViewController

                    infoViewCtrl.japanese = japanese.string
                    infoViewCtrl.english = sentence.english?.htmlAttributedString?.string
                    infoViewCtrl.furigana = japanese.furigana ?? [Furigana]()
                    infoViewCtrl.showEnglish = !(Account.currentAccount?.englishMode ?? false)

                    show(infoViewCtrl, sender: self)
                }
            }

        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return section == 1 ? selectionSectionHeaderView : nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? 46 : 0
    }
}

extension GrammarTableViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    override var previewActionItems: [UIPreviewActionItem] {
        if let review = grammar?.review, review.complete {
            return [
                UIPreviewAction(title: L10n.Review.Edit.remove, style: .destructive) { _, _ in
                    AppDelegate.modifyReview(.remove(self.grammar!.review!.identifier))
                },
                UIPreviewAction(title: L10n.Review.Edit.reset, style: .destructive) { _, _ in
                    AppDelegate.modifyReview(.reset(self.grammar!.review!.identifier))
                }
            ]
        } else {
            return [
                UIPreviewAction(title: L10n.Review.Edit.add, style: .default) { _, _ in
                    AppDelegate.modifyReview(.add(self.grammar!.identifier))
                }
            ]
        }
    }
}

extension GrammarTableViewController: GrammarFetchedResultsControllerDelegate {
    func fetchedResultsDidChange() {
        tableView.reloadData()
    }
}
