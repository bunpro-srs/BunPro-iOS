//
//  Created by Andreas Braun on 21.07.19.
//  Copyright © 2019 Andreas Braun. All rights reserved.
//

import AVFoundation
import Combine
import CoreData
import UIKit

class SentencesTableViewController: CoreDataFetchedResultsTableViewController<Sentence> {
    var grammar: Grammar?

    private var player: AVPlayer?

    private var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.Grammar.sentences

        setupFetchedResultsController()

        NotificationCenter
            .default
            .publisher(for: NSNotification.Name.AVPlayerItemDidPlayToEndTime)
            .sink { _ in
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
            .store(in: &subscriptions)
    }

    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Sentence> = Sentence.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "grammar = %@", grammar!)

        let sort = NSSortDescriptor(key: #keyPath(Sentence.identifier), ascending: true)
        fetchRequest.sortDescriptors = [sort]

        fetchRequest.fetchLimit = AppDelegate.numberOfAllowedSentences

        fetchedResultsController = NSFetchedResultsController<Sentence>(
            fetchRequest: fetchRequest,
            managedObjectContext: AppDelegate.database.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as DetailCell

        let sentence = fetchedResultsController.object(at: indexPath)

        let japaneseFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 15))
        let englishFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: UIFont.systemFont(ofSize: 12))

        cell.attributedName = sentence
            .japanese?
            .cleanStringAndFurigana
            .string
            .htmlAttributedString(
                font: japaneseFont,
                color: view.tintColor
            )?
            .string

        cell.attributedDescriptionText = sentence
            .english?
            .htmlAttributedString(
                font: englishFont,
                color: .white
            )?
            .string

        cell.actionImage = sentence.audioURL != nil ? .playCircle : nil

        cell.customAction = { [weak self] _ in self?.playSound(forSentenceAt: indexPath) }
        cell.isDescriptionLabelHidden = Account.currentAccount?.englishMode ?? false

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sentence = fetchedResultsController.object(at: indexPath)

        if let japanese = sentence.japanese?.cleanStringAndFurigana {
            let infoViewCtrl = StoryboardScene.GrammarDetail.kanjiTableViewController.instantiate()

            infoViewCtrl.japanese = japanese.string
            infoViewCtrl.english = sentence.english?.htmlAttributedString?.string
            infoViewCtrl.furigana = japanese.furigana ?? [Furigana]()
            infoViewCtrl.showEnglish = !(Account.currentAccount?.englishMode ?? false)

            show(infoViewCtrl, sender: self)
        }
    }

    private func playSound(forSentenceAt indexPath: IndexPath) {
        guard let url = fetchedResultsController.object(at: indexPath).audioURL else { return }

        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)

        if player == nil {
            player = AVPlayer(url: url)
            player?.volume = 1.0

            player?.actionAtItemEnd = .pause
        } else {
            player?.pause()

            let item = AVPlayerItem(url: url)
            player?.replaceCurrentItem(with: item)
        }

        player?.play()
    }
}
