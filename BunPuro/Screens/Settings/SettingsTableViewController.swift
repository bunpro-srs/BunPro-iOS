//
//  Created by Andreas Braun on 06.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import BunProKit
import Combine
import CoreData
import MessageUI
import ProcedureKit
import Protocols
import SafariServices
import UIKit

final class SettingsTableViewController: UITableViewController, SegueHandler {
    enum SegueIdentifier: String {
        case privacy = "present privacy"
        case about = "present about"
        case terms = "present terms"
    }

    private enum Section: Int {
        case settings
        case information
        case appearance
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
    }

    @IBOutlet private weak var furiganaDetailLabel: UILabel!
    @IBOutlet private weak var hideEnglishDetailLabel: UILabel!
    @IBOutlet private weak var bunnyModeDetailLabel: UILabel!
    @IBOutlet private weak var appearanceLabel: UILabel!

    private let queue = ProcedureQueue()
    private var settings: SetSettingsProcedure.Settings? {
        didSet {
            furiganaDetailLabel?.text = settings?.furigana.localizedString
            hideEnglishDetailLabel?.text = settings?.english.localizedString
            bunnyModeDetailLabel?.text = settings?.bunnyMode.localizedString
        }
    }

    private var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &subscriptions)

        appearanceLabel.text = UserDefaults.standard.userInterfaceStyle.localizedTitle

        UserDefaults.standard
            .publisher(for: \.userInterfaceStyle)
            .map { $0.localizedTitle }
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: appearanceLabel)
            .store(in: &subscriptions)

        updateUI()
    }

    private var account: Account? {
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.fetchBatchSize = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Account.name), ascending: true)]

        do {
            return try AppDelegate.database.viewContext.fetch(fetchRequest).first
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

        case .information:

            guard let info = Info(rawValue: indexPath.row) else { return }
            switch info {
            case .community:
                guard let url = info.url else { return }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)

            case .contact:
                let url = URL(string: "mailto:feedback@mail.bunpro.jp")!
                UIApplication.shared.open(url, options: [:], completionHandler: nil)

            case .about, .privacy, .terms:
                break
            }

        case .appearance:

            switch indexPath.row {
            case 0:
                didSelectAppearanceCell(cell)

            default:
                break
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

    private func didSelectAppearanceCell(_ cell: UITableViewCell) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let systemAction = UIAlertAction(title: UserDefaults.UserInterfaceStyle.system.localizedTitle, style: .default) { _ in
            UserDefaults.standard.userInterfaceStyle = .system
        }

        let lightAction = UIAlertAction(title: UserDefaults.UserInterfaceStyle.light.localizedTitle, style: .default) { _ in
            UserDefaults.standard.userInterfaceStyle = .light
        }

        let darkAction = UIAlertAction(title: UserDefaults.UserInterfaceStyle.dark.localizedTitle, style: .default) { _ in
            UserDefaults.standard.userInterfaceStyle = .dark
        }

        let bunproAction = UIAlertAction(title: UserDefaults.UserInterfaceStyle.bunpro.localizedTitle, style: .default) { _ in
            UserDefaults.standard.userInterfaceStyle = .bunpro
        }

        let cancelAction = UIAlertAction(title: L10n.General.cancel, style: .cancel, handler: nil)

        controller.addAction(systemAction)
        controller.addAction(lightAction)
        controller.addAction(darkAction)
        controller.addAction(bunproAction)
        controller.addAction(cancelAction)

        controller.popoverPresentationController?.sourceView = cell
        controller.popoverPresentationController?.sourceRect = cell.bounds

        present(controller, animated: true, completion: nil)
    }

    private func didSelectLogoutCell(_ cell: UITableViewCell) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let logoutAction = UIAlertAction(title: L10n.Settings.Logout.action, style: .destructive) { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true) {
                Server.logout()
            }

            self?.tabBarController?.selectedIndex = 0
        }

        let cancelAction = UIAlertAction(title: L10n.General.cancel, style: .cancel, handler: nil)

        controller.addAction(logoutAction)
        controller.addAction(cancelAction)

        controller.popoverPresentationController?.sourceView = cell
        controller.popoverPresentationController?.sourceRect = cell.bounds

        present(controller, animated: true, completion: nil)
    }

    private func updateUI() {
        guard let account = Account.currentAccount else { return }

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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .privacy:
            (segue.destination.content as? InformationTableViewController)?.category = .privacy

        case .about:
            (segue.destination.content as? InformationTableViewController)?.category = .about

        case .terms:
            (segue.destination.content as? InformationTableViewController)?.category = .terms
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
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
            return nil // URL(string: "https://bunpro.jp/about")

        case .contact:
            return URL(string: "https://bunpro.jp/contact")

        case .privacy:
            return nil // URL(string: "https://bunpro.jp/privacy")

        case .terms:
            return nil // URL(string: "https://bunpro.jp/terms")
        }
    }
}
