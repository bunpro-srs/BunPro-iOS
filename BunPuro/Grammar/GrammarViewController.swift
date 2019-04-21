//
//  Created by Andreas Braun on 21.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import AVFoundation
import BunPuroKit
import CoreData
import SafariServices
import UIKit

protocol GrammarPresenter {
    var grammar: Grammar? { get set }
}

final class GrammarViewController: UITableViewController, GrammarPresenter {
    enum ViewMode: Int {
        case examples
        case reading
    }

    @IBOutlet private var selectionSectionHeaderView: UIView!
    @IBOutlet private weak var viewModeSegmentedControl: UISegmentedControl!
    @IBOutlet private var reviewEditBarButtonItem: UIBarButtonItem!

    private var exampleSentencesFetchedResultsController: NSFetchedResultsController<Sentence>!
    private var readingsFetchedResultsController: NSFetchedResultsController<Link>!
    private var player: AVPlayer?

    var grammar: Grammar?

    private var review: Review? {
        return grammar?.review
    }

    private lazy var account: Account? = {
        return Account.currentAccount
    }()

    private var viewMode: ViewMode = .examples {
        didSet {
            viewModeSegmentedControl?.selectedSegmentIndex = viewMode.rawValue

            tableView.reloadData()
        }
    }

    private var beginUpdateObserver: NSObjectProtocol?
    private var endUpdateObserver: NSObjectProtocol?

    deinit {
        log.info("deinit \(String(describing: self))")

        for observer in [beginUpdateObserver, endUpdateObserver] where observer != nil {
            NotificationCenter.default.removeObserver(observer!)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = Asset.background.color

        assert(grammar != nil)

        updateEditBarButtonState()

        beginUpdateObserver = NotificationCenter.default.addObserver(forName: .BunProWillBeginUpdating, object: nil, queue: OperationQueue.main) { _ in
                let activityIndicator = UIActivityIndicatorView(style: .white)
                activityIndicator.startAnimating()

                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        }

        endUpdateObserver = NotificationCenter.default.addObserver(
            forName: .BunProDidEndUpdating,
            object: nil,
            queue: nil) { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) { [weak self] in
                    self?.navigationItem.rightBarButtonItem = self?.reviewEditBarButtonItem

                    if let numberOfRows = self?.tableView.numberOfRows(inSection: 0) {
                        let complete = self?.review?.complete ?? false

                        switch (numberOfRows, complete) {
                        case (2, true):

                            let indexPath = IndexPath(row: Info.streak.rawValue, section: 0)

                            self?.tableView.beginUpdates()
                            self?.tableView.insertRows(at: [indexPath], with: .fade)
                            self?.tableView.endUpdates()

                        case (3, false):

                            let indexPath = IndexPath(row: Info.streak.rawValue, section: 0)

                            self?.tableView.beginUpdates()
                            self?.tableView.deleteRows(at: [indexPath], with: .fade)
                            self?.tableView.endUpdates()

                        case (3, true):

                            let indexPath = IndexPath(row: Info.streak.rawValue, section: 0)

                            self?.tableView.beginUpdates()
                            self?.tableView.reloadRows(at: [indexPath], with: .none)
                            self?.tableView.endUpdates()

                        default:
                            break
                        }

                        self?.updateEditBarButtonState()
                    }
                }
        }

        setupSentencesFetchedResultsController()
        setupReadingsFetchedResultsController()
    }

    @IBAction private func viewModeChanged(_ sender: UISegmentedControl) {
        guard let newViewMode = ViewMode(rawValue: sender.selectedSegmentIndex) else {
            fatalError("ViewMode (\(sender.selectedSegmentIndex)) not supported.")
        }

        viewMode = newViewMode
    }

    @IBAction private func edidReviewButtonPressed(_ sender: UIBarButtonItem) {
        if review?.complete == true {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            let removeAction = UIAlertAction(
                title: L10n.Review.Edit.remove,
                style: .destructive) { _ in
                    self.modifyReview(.remove(self.review!.identifier))
            }

            alertController.addAction(removeAction)

            let resetAction = UIAlertAction(
                title: L10n.Review.Edit.reset,
                style: .destructive) { _ in
                    self.modifyReview(.reset(self.review!.identifier))
            }

            alertController.addAction(resetAction)

            alertController.addAction(
                UIAlertAction(title: L10n.General.cancel, style: .cancel, handler: nil)
            )

            alertController.popoverPresentationController?.barButtonItem = sender

            present(alertController, animated: true)
        } else {
            modifyReview(.add(grammar!.identifier))
        }
    }

    private func updateEditBarButtonState() {
        reviewEditBarButtonItem?.title = review?.complete == true ? L10n.Review.Edit.Button.removeReset : L10n.Review.Edit.Button.add
        reviewEditBarButtonItem.isEnabled = AppDelegate.isContentAccessable
    }

    private func modifyReview(_ modificationType: ModifyReviewProcedure.ModificationType) {
        AppDelegate.modifyReview(modificationType)
    }

    private func setupSentencesFetchedResultsController() {
        let request: NSFetchRequest<Sentence> = Sentence.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(Sentence.grammar), grammar!)

        let sort = NSSortDescriptor(key: #keyPath(Sentence.identifier), ascending: true)
        request.sortDescriptors = [sort]

        request.fetchLimit = AppDelegate.numberOfAllowedSentences

        exampleSentencesFetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        exampleSentencesFetchedResultsController?.delegate = self

        do {
            try exampleSentencesFetchedResultsController?.performFetch()
        } catch {
            log.error(error)
        }
    }

    private func setupReadingsFetchedResultsController() {
        let request: NSFetchRequest<Link> = Link.fetchRequest()
        request.predicate = NSPredicate(format: "%K = %@", #keyPath(Link.grammar), grammar!)

        let sort = NSSortDescriptor(key: #keyPath(Link.id), ascending: true)
        request.sortDescriptors = [sort]

        readingsFetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: AppDelegate.coreDataStack.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        readingsFetchedResultsController?.delegate = self

        do {
            try readingsFetchedResultsController?.performFetch()
        } catch {
            log.error(error)
        }
    }

    private func playSound(forSentenceAt indexPath: IndexPath) {
        guard let url = exampleSentencesFetchedResultsController.object(at: indexPath).audioURL else { return }

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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return review?.complete == true ? 3 : 2

        default:
            switch viewMode {
            case .examples:
                let subscribed = AppDelegate.isContentAccessable
                let actualNumberOfObjects = (exampleSentencesFetchedResultsController?.fetchedObjects?.count ?? 0)
                return subscribed ? actualNumberOfObjects : actualNumberOfObjects > 0 ? 1 : 0

            case .reading:
                return readingsFetchedResultsController?.fetchedObjects?.count ?? 0
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

                let cell = tableView.dequeueReusableCell(for: indexPath) as BasicInfoCell

                cell.titleLabel.text = grammar?.title
                cell.meaningLabel.text = grammar?.meaning

                let englishFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 12))

                if let caution = grammar?.caution?.replacingOccurrences(of: "<span class='chui'>", with: "").replacingOccurrences(of: "</span>", with: ""), let attributed = "⚠️ \(caution)".htmlAttributedString(font: englishFont, color: .white), !caution.isEmpty {
                    cell.cautionLabel.attributedText = attributed
                } else {
                    cell.cautionLabel.attributedText = nil
                    cell.cautionLabel.isHidden = true
                }

                cell.separatorInset = UIEdgeInsets(top: 0, left: 100_000, bottom: 0, right: 0)

                return cell

            case .structure:

                let cell = tableView.dequeueReusableCell(for: indexPath) as StructureInfoCell

                let englishFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 12))

                cell.descriptionLabel.attributedText = grammar?.structure?.replacingOccurrences(of: ", ", with: "</br>").htmlAttributedString(font: englishFont, color: .white)

                cell.separatorInset = UIEdgeInsets(top: 0, left: 100_000, bottom: 0, right: 0)

                return cell

            case .streak:

                let cell = tableView.dequeueReusableCell(for: indexPath) as StreakInfoCell
                cell.streak = Int(review?.streak ?? 0)

                return cell
            }

        default:
            let cell = tableView.dequeueReusableCell(for: indexPath) as DetailCell

            cell.longPressGestureRecognizer = nil

            switch viewMode {
            case .examples:

                let correctIndexPath = IndexPath(row: indexPath.row, section: 0)

                let sentence = exampleSentencesFetchedResultsController.object(at: correctIndexPath)

                let japaneseFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 15))
                let englishFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 12))

                cell.nameLabel?.attributedText = sentence.japanese?.cleanStringAndFurigana.string.htmlAttributedString(font: japaneseFont, color: Asset.mainTint.color)
                cell.descriptionLabel?.attributedText = sentence.english?.htmlAttributedString(font: englishFont, color: .white)
                cell.actionImage = sentence.audioURL != nil ? #imageLiteral(resourceName: "play") : nil

                cell.customAction = { [weak self] _ in
                    self?.playSound(forSentenceAt: correctIndexPath)
                }

                cell.descriptionLabel?.isHidden = account?.englishMode ?? false

                cell.selectionStyle = .none

                if cell.longPressGestureRecognizer == nil {
                    cell.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
                    cell.addGestureRecognizer(cell.longPressGestureRecognizer!)
                }

            case .reading:

                let correctIndexPath = IndexPath(row: indexPath.row, section: 0)

                let link = readingsFetchedResultsController.object(at: correctIndexPath)

                let font1 = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 12))
                let font2 = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 10))

                cell.nameLabel?.attributedText = link.site?.htmlAttributedString(font: font1, color: Asset.mainTint.color)
                cell.descriptionLabel?.attributedText = link.about?.htmlAttributedString(font: font2, color: .white)
                cell.descriptionLabel.isHidden = false
                cell.customAction = nil
                cell.actionImage = nil

                cell.selectionStyle = .none
            }

            return cell
        }
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

            defer {
                tableView.deselectRow(at: indexPath, animated: true)
            }

            switch viewMode {
            case .reading:

                let correctIndexPath = IndexPath(row: indexPath.row, section: 0)
                guard let url = readingsFetchedResultsController.object(at: correctIndexPath).url else { return }

                let safariViewController = SFSafariViewController(url: url)

                present(safariViewController, animated: true, completion: nil)

            case .examples:

                let correctIndexPath = IndexPath(row: indexPath.row, section: 0)

                let sentence = exampleSentencesFetchedResultsController.object(at: correctIndexPath)

                if let japanese = sentence.japanese?.cleanStringAndFurigana {
                    let infoViewController = storyboard!.instantiateViewController() as KanjiTableViewController

                    infoViewController.japanese = japanese.string
                    infoViewController.english = sentence.english?.htmlAttributedString?.string
                    infoViewController.furigana = japanese.furigana ?? [Furigana]()
                    infoViewController.showEnglish = !(account?.englishMode ?? false)

                    show(infoViewController, sender: self)
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
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let copyJapanese = UIAlertAction(title: L10n.Copy.japanese, style: .default) { [weak self] _ in
            UIPasteboard.general.string = self?.grammar?.title
        }

        let copyMeaning = UIAlertAction(title: L10n.Copy.meaning, style: .default) { [weak self] _ in
            UIPasteboard.general.string = self?.grammar?.meaning
        }

        alertController.addAction(copyJapanese)
        alertController.addAction(copyMeaning)

        alertController.addAction(UIAlertAction(title: L10n.General.cancel, style: .cancel))

        alertController.popoverPresentationController?.sourceView = cell
        alertController.popoverPresentationController?.sourceRect = cell.bounds

        present(alertController, animated: true)
    }

    private func showCopyJapaneseOrEnglish(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        let correctIndexPath = IndexPath(row: indexPath.row, section: 0)

        let sentence = exampleSentencesFetchedResultsController.object(at: correctIndexPath)

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let copyJapanese = UIAlertAction(title: L10n.Copy.japanese, style: .default) { _ in
            UIPasteboard.general.string = sentence.japanese?.htmlAttributedString?.string.cleanStringAndFurigana.string
        }

        let copyMeaning = UIAlertAction(title: L10n.Copy.english, style: .default) { _ in
            UIPasteboard.general.string = sentence.english?.htmlAttributedString?.string
        }

        alertController.addAction(copyJapanese)
        alertController.addAction(copyMeaning)

        alertController.addAction(UIAlertAction(title: L10n.General.cancel, style: .cancel))

        alertController.popoverPresentationController?.sourceView = cell
        alertController.popoverPresentationController?.sourceRect = cell.bounds

        present(alertController, animated: true)
    }
}

extension GrammarViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    override var previewActionItems: [UIPreviewActionItem] {
        if let review = review, review.complete {
            let removeAction = UIPreviewAction(title: L10n.Review.Edit.remove, style: .destructive) { _, _ in
                self.modifyReview(.remove(self.review!.identifier))
            }

            let resetAction = UIPreviewAction(title: L10n.Review.Edit.reset, style: .destructive) { _, _ in
                self.modifyReview(.reset(self.review!.identifier))
            }

            return [removeAction, resetAction]
        } else {
            let addAction = UIPreviewAction(title: L10n.Review.Edit.add, style: .default) { _, _ in
                self.modifyReview(.add(self.grammar!.identifier))
            }

            return [addAction]
        }
    }
}

extension GrammarViewController: NSFetchedResultsControllerDelegate {
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        tableView.reloadData()
    }
}
