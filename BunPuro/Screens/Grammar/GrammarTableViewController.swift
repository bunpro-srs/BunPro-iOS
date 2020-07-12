//
//  Created by Andreas Braun on 21.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import BunProKit
import SafariServices
import UIKit

protocol GrammarPresenter {
    var grammar: Grammar? { get set }
}

final class GrammarTableViewController: UITableViewController, GrammarPresenter {
    @IBOutlet private var reviewEditBarButtonItem: UIBarButtonItem!

    private let fetchedResultsController = GrammarFetchedResultsController()
    private let flowController = GrammarFlowController()

    var grammar: Grammar?

    private var statusObserver: StatusObserverProtocol?

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(grammar != nil)

        title = grammar?.title

        statusObserver = StatusObserver()

        updateEditBarButtonState()

        statusObserver?.willBeginUpdating = { [weak self] in
            let activityIndicator: UIActivityIndicatorView

            activityIndicator = UIActivityIndicatorView(style: .medium)

            activityIndicator.startAnimating()
            self?.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        }

        statusObserver?.didEndUpdating = { [weak self] in
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

        setupKeyCommands()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        becomeFirstResponder()
    }

    @IBAction private func editReviewButtonPressed(_ sender: UIBarButtonItem) {
        flowController.editReviewButtonPressed(grammar: grammar!, barButtonItem: sender, viewController: self)
    }

    @objc
    func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

    private func updateEditBarButtonState() {
        reviewEditBarButtonItem.image = UIImage(systemName: "ellipsis.circle")

        if #available(iOS 14.0, *) {
            reviewEditBarButtonItem.action = nil

            guard let grammar = grammar else { return }

            let complete = grammar.review?.complete ?? false

            reviewEditBarButtonItem.menu = UIMenu(
                title: L10n.Review.Edit.Menu.review,
                children: [
                    UIAction(title: L10n.Review.Edit.Add.short, image: .repeat, attributes: complete ? .hidden : []) { _ in
                        AppDelegate.modifyReview(.add(grammar.identifier))
                    },
                    UIAction(title: L10n.Review.Edit.Reset.short, image: .repeatOne, attributes: complete ? .destructive : .hidden) { _ in
                        guard let review = grammar.review else { return }
                        AppDelegate.modifyReview(.reset(review.identifier))
                    },
                    UIAction(title: L10n.Review.Edit.Remove.short, image: .trashFill, attributes: complete ? .destructive : .hidden) { _ in
                        guard let review = grammar.review else { return }
                        AppDelegate.modifyReview(.remove(review.identifier))
                    },
                    UIMenu(
                        title: L10n.Review.Edit.Menu.copy,
                        options: .displayInline,
                        children: [
                            UIAction(title: L10n.Copy.japanese, image: .docOnDocFill) { [weak self] _ in
                                self?.copyJapanese()
                            },
                            UIAction(title: L10n.Copy.meaning, image: .docOnDocFill) { [weak self] _ in
                                self?.copyMeaning()
                            }
                        ]
                    )
                ]
            )
        }

        reviewEditBarButtonItem.isEnabled = AppDelegate.isContentAccessable
    }

    private func showCopyJapaneseOrMeaning(at indexPath: IndexPath) {
        showCopyActionSheet(
            at: indexPath,
            actions: [
                UIAlertAction(title: L10n.Copy.japanese, style: .default) { [weak self] _ in
                    self?.copyJapanese()
                },
                UIAlertAction(title: L10n.Copy.meaning, style: .default) { [weak self] _ in
                    self?.copyMeaning()
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
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1

        default:
            return 2
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
            return basicInfoCell(tableView, indexPath)

        default:
            return detailCell(tableView, indexPath)
        }
    }

    private func basicInfoCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as BasicInfoCell

        cell.titleLabel.text = grammar?.title
        cell.meaningLabel.text = grammar?.meaning

        let englishFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 12))

        if let caution = grammar?.caution?.replacingOccurrences(of: "<span class='chui'>", with: "").replacingOccurrences(of: "</span>", with: ""),
           let attributed = "⚠️ \(caution)".htmlAttributedString(font: englishFont, color: .white),
           !caution.isEmpty {
            cell.cautionLabel.text = attributed.string
        } else {
            cell.cautionLabel.text = nil
            cell.cautionLabel.isHidden = true
        }

        cell.attributedDescription = grammar?
            .structure?
            .replacingOccurrences(of: ", ", with: "</br>")
            .htmlAttributedString(font: englishFont, color: .white)?
            .string

        cell.streak = Int(grammar?.review?.streak ?? 0)
        cell.contentStackView?.isHidden = grammar?.review?.complete == false

        return cell
    }

    private func detailCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as UITableViewCell

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = L10n.Grammar.sentences
            cell.detailTextLabel?.text = "\(fetchedResultsController.exampleSentencesCount())"

        case 1:
            cell.textLabel?.text = L10n.Grammar.readings
            cell.detailTextLabel?.text = "\(fetchedResultsController.readingsCount())"

        default:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            showCopyJapaneseOrMeaning(at: indexPath)

        case 1:
            defer { tableView.deselectRow(at: indexPath, animated: true) }

            switch indexPath.row {
            case 0:
                let controller = StoryboardScene.GrammarDetail.sentencesTableViewController.instantiate()
                controller.grammar = grammar

                show(controller, sender: self)

            case 1:
                let controller = StoryboardScene.GrammarDetail.readingsTableViewController.instantiate()
                controller.grammar = grammar

                show(controller, sender: self)

            default:
                break
            }

        default:
            break
        }
    }
}

extension GrammarTableViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
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

extension GrammarTableViewController {
    fileprivate func setupKeyCommands() {
        addKeyCommand(
            UIKeyCommand(
                title: L10n.Copy.japanese,
                action: #selector(copyJapanese),
                input: "C",
                modifierFlags: .command
            )
        )

        addKeyCommand(
            UIKeyCommand(
                title: L10n.Copy.meaning,
                action: #selector(copyMeaning),
                input: "C",
                modifierFlags: [.command, .shift]
            )
        )
    }

    @objc
    private func copyJapanese() {
        UIPasteboard.general.string = grammar?.title
    }

    @objc
    private func copyMeaning() {
        UIPasteboard.general.string = grammar?.meaning
    }
}
