//
//  Created by Andreas Braun on 06.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import MessageUI
import ProcedureKit
import SafariServices
import UIKit

final class SettingsTableViewController: UITableViewController {
    private enum Section: Int {
        case settings
        case subscription
        case information
        case logout
    }

    private enum Setting: Int {
        case furigana
        case english
        case bunny
    }

    fileprivate enum Info: Int {
        case community
        case about
        case contact
        case privacy
        case terms
        case debug
    }

    @IBOutlet private weak var furiganaDetailLabel: UILabel!
    @IBOutlet private weak var hideEnglishDetailLabel: UILabel!
    @IBOutlet private weak var bunnyModeDetailLabel: UILabel!
    @IBOutlet private weak var subscriptionDetailLabel: UILabel!

    private let queue = ProcedureQueue()
    private var settings: SetSettingsProcedure.Settings? {
        didSet {
            furiganaDetailLabel?.text = settings?.furigana.localizedString
            hideEnglishDetailLabel?.text = settings?.english.localizedString
            bunnyModeDetailLabel?.text = settings?.bunnyMode.localizedString
        }
    }

    private var saveObserver: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        saveObserver = NotificationCenter.default.observe(name: .NSManagedObjectContextDidSave, object: nil, queue: .main) { [weak self] _ in
            self?.updateUI()
        }

        updateUI()
    }

    private var account: Account? {
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.fetchBatchSize = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Account.name), ascending: true)]

        do {
            return try AppDelegate.coreDataStack.managedObjectContext.fetch(fetchRequest).first
        } catch {
            log.error(error)
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableView.cellForRow(at: indexPath)!

        switch Section(rawValue: indexPath.section)! {
        case .settings:
            switch Setting(rawValue: indexPath.row)! {
            case .furigana:
                didSelectFuriganaSettingsCell(cell)

            case .english:
                didSelectEnglishSettingsCell(cell)

            case .bunny:
                didSelectBunnySettingsCell(cell)
            }

        case .subscription:
            break

        case .information:
            let info = Info(rawValue: indexPath.row)!
            switch info {
            case .debug:
                didSelectDebugSubscriptionCell()

            default:
                guard let url = info.url else { return }
                present(customSafariViewController(url: url), animated: true)
            }

        case .logout:
            switch indexPath.row {
            case 0:
                didSelectLogoutCell(cell)

            default:
                break
            }
        }
    }

    private func didSelectFuriganaSettingsCell(_ cell: UITableViewCell) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let yesAction = UIAlertAction(title: FuriganaMode.on.localizedString, style: .default) { _ in
            self.settings?.furigana = .on
            self.synchronizeSettings()
        }

        let noAction = UIAlertAction(title: FuriganaMode.off.localizedString, style: .default) { _ in
            self.settings?.furigana = .off
            self.synchronizeSettings()
        }

        let wanikaniAction = UIAlertAction(title: FuriganaMode.wanikani.localizedString, style: .default) { _ in
            self.settings?.furigana = .wanikani
            self.synchronizeSettings()
        }

        let cancelAction = UIAlertAction(title: L10n.General.cancel, style: .cancel, handler: nil)

        controller.addAction(yesAction)
        controller.addAction(noAction)
        controller.addAction(wanikaniAction)
        controller.addAction(cancelAction)

        controller.preferredAction = wanikaniAction

        controller.popoverPresentationController?.sourceView = cell
        controller.popoverPresentationController?.sourceRect = cell.bounds

        present(controller, animated: true, completion: nil)
    }

    private func didSelectEnglishSettingsCell(_ cell: UITableViewCell) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let yesAction = UIAlertAction(title: Active.yes.localizedString, style: .default) { _ in
            self.settings?.english = .yes
            self.synchronizeSettings()
        }

        let noAction = UIAlertAction(title: Active.no.localizedString, style: .default) { _ in
            self.settings?.english = .no
            self.synchronizeSettings()
        }

        let cancelAction = UIAlertAction(title: L10n.General.cancel, style: .cancel, handler: nil)

        controller.addAction(yesAction)
        controller.addAction(noAction)
        controller.addAction(cancelAction)

        controller.popoverPresentationController?.sourceView = cell
        controller.popoverPresentationController?.sourceRect = cell.bounds

        present(controller, animated: true, completion: nil)
    }

    private func didSelectBunnySettingsCell(_ cell: UITableViewCell) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let onAction = UIAlertAction(title: State.on.localizedString, style: .default) { _ in
            self.settings?.bunnyMode = .on
            self.synchronizeSettings()
        }

        let offAction = UIAlertAction(title: State.off.localizedString, style: .default) { _ in
            self.settings?.bunnyMode = .off
            self.synchronizeSettings()
        }

        let cancelAction = UIAlertAction(title: L10n.General.cancel, style: .cancel, handler: nil)

        controller.addAction(onAction)
        controller.addAction(offAction)
        controller.addAction(cancelAction)

        controller.popoverPresentationController?.sourceView = cell
        controller.popoverPresentationController?.sourceRect = cell.bounds

        present(controller, animated: true, completion: nil)
    }

    private func didSelectDebugSubscriptionCell() {
        let fetchRequest: NSFetchRequest<Review> = Review.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K <= %@ && complete = true", #keyPath(Review.nextReviewDate), NSDate())
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Review.identifier), ascending: true)
        ]

        var string = ""

        do {
            let reviews = try AppDelegate.coreDataStack.storeContainer.viewContext.fetch(fetchRequest)
            string = reviews.description
        } catch {
            log.error(error)
            string = String(describing: error)
        }

        let emailViewCtrl = MFMailComposeViewController()
        emailViewCtrl.setSubject("BunPro bad reviews")
        emailViewCtrl.setMessageBody(string, isHTML: true)
        emailViewCtrl.setToRecipients(["rion-kaneshiro@gmx.net"])

        emailViewCtrl.mailComposeDelegate = self

        present(emailViewCtrl, animated: true, completion: nil)
    }

    private func didSelectLogoutCell(_ cell: UITableViewCell) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let logoutAction = UIAlertAction(title: L10n.Settings.Logout.action, style: .destructive) { _ in
            Server.logout()
            self.tabBarController?.selectedIndex = 0
        }

        let cancelAction = UIAlertAction(title: L10n.General.cancel, style: .cancel, handler: nil)

        controller.addAction(logoutAction)
        controller.addAction(cancelAction)

        controller.popoverPresentationController?.sourceView = cell
        controller.popoverPresentationController?.sourceRect = cell.bounds

        present(controller, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch Section(rawValue: indexPath.section)! {
        case .subscription:
            switch Info(rawValue: indexPath.row)! {
            case .debug:
                return 0

            default:
                return super.tableView(tableView, heightForRowAt: indexPath)
            }

        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }

    private func updateUI() {
        guard let account = self.account else {
            subscriptionDetailLabel?.text = L10n.Subscription.unknown
            return
        }

        subscriptionDetailLabel?.text = account.subscriber ? L10n.Subscription.subscribed : L10n.Subscription.unsubscribed

        guard let furigana = FuriganaMode(rawValue: account.furiganaMode ?? "") else { return }
        let english = account.englishMode ? Active.yes : Active.no
        let bunnyMode = account.bunnyMode ? State.on : State.off

        settings = SetSettingsProcedure.Settings(furigana: furigana, english: english, bunnyMode: bunnyMode)
    }

    private func synchronizeSettings() {
        guard let settings = settings else { return }
        let settingsProcedure = SetSettingsProcedure(presentingViewController: self, settings: settings) { user, error in
            guard let user = user, error == nil else {
                log.info(String(describing: error))
                return
            }

            DispatchQueue.main.async {
                let importProcedure = ImportAccountIntoCoreDataProcedure(account: user)
                Server.add(procedure: importProcedure)
            }
        }

        Server.add(procedure: settingsProcedure)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    private func customSafariViewController(url: URL) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true

        let safariViewCtrl = SFSafariViewController(url: url, configuration: configuration)

        return safariViewCtrl
    }
}

extension SettingsTableViewController: UINavigationControllerDelegate { }
extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}

extension Active {
    var localizedString: String {
        switch self {
        case .yes:
            return L10n.Active.yes

        case .no:
            return L10n.Active.no
        }
    }
}

extension State {
    var localizedString: String {
        switch self {
        case .on:
            return L10n.State.on

        case .off:
            return L10n.State.off
        }
    }
}

extension FuriganaMode {
    var localizedString: String {
        switch self {
        case .on:
            return L10n.Furigana.on

        case .off:
            return L10n.Furigana.off

        case .wanikani:
            return L10n.Furigana.wanikani
        }
    }
}

extension SettingsTableViewController.Info {
    var url: URL? {
        switch self {
        case .community:
            return URL(string: "https://community.bunpro.jp/")

        case .about:
            return URL(string: "https://bunpro.jp/about")

        case .contact:
            return URL(string: "https://bunpro.jp/contact")

        case .privacy:
            return URL(string: "https://bunpro.jp/privacy")

        case .terms:
            return URL(string: "https://bunpro.jp/terms")

        case .debug:
            return nil
        }
    }
}
