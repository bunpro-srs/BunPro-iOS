//
//  SettingsTableViewController.swift
//  BunPuro
//
//  Created by Andreas Braun on 06.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import CoreData
import ProcedureKit
import BunPuroKit
import SafariServices

class SettingsTableViewController: UITableViewController {
    
    private enum Section: Int {
        case settings
        case subscription
        case logout
    }
    
    private enum Setting: Int {
        case furigana
        case english
//        case reviewEnglish
        case bunny
    }
    
    private enum Info: Int {
        case subscription
        case empty
        case community
        case about
        case contact
        case privacy
        case terms
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundImageView = UIImageView(image: #imageLiteral(resourceName: "background"))
        backgroundImageView.contentMode = .scaleAspectFill
        
        tableView.backgroundView = backgroundImageView
        tableView.backgroundView?.addMotion()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextDidSave, object: nil, queue: OperationQueue.main) { (_) in
            self.updateUI()
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
            print(error)
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
                let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                let yesAction = UIAlertAction(title: FuriganaMode.on.localizedString, style: .default) { (_) in
                    self.settings?.furigana = .on
                    self.synchronizeSettings()
                }
                
                let noAction = UIAlertAction(title: FuriganaMode.off.localizedString, style: .default) { (_) in
                    self.settings?.furigana = .off
                    self.synchronizeSettings()
                }
                
                let wanikaniAction = UIAlertAction(title: FuriganaMode.wanikani.localizedString, style: .default) { (_) in
                    self.settings?.furigana = .wanikani
                    self.synchronizeSettings()
                }
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("general.cancel", comment: ""), style: .cancel, handler: nil)
                
                controller.addAction(yesAction)
                controller.addAction(noAction)
                controller.addAction(wanikaniAction)
                controller.addAction(cancelAction)
                
                controller.preferredAction = wanikaniAction
                
                controller.popoverPresentationController?.sourceView = cell
                controller.popoverPresentationController?.sourceRect = cell.bounds
                
                present(controller, animated: true, completion: nil)
                
            case .english:
                let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                let yesAction = UIAlertAction(title: Active.yes.localizedString, style: .default) { (_) in
                    self.settings?.english = .yes
                    self.synchronizeSettings()
                }
                
                let noAction = UIAlertAction(title: Active.no.localizedString, style: .default) { (_) in
                    self.settings?.english = .no
                    self.synchronizeSettings()
                }
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("general.cancel", comment: ""), style: .cancel, handler: nil)
                
                controller.addAction(yesAction)
                controller.addAction(noAction)
                controller.addAction(cancelAction)
                
                controller.popoverPresentationController?.sourceView = cell
                controller.popoverPresentationController?.sourceRect = cell.bounds
                
                present(controller, animated: true, completion: nil)
//            case .reviewEnglish:
                
            case .bunny:
                let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                let onAction = UIAlertAction(title: State.on.localizedString, style: .default) { (_) in
                    self.settings?.bunnyMode = .on
                    self.synchronizeSettings()
                }
                
                let offAction = UIAlertAction(title: State.off.localizedString, style: .default) { (_) in
                    self.settings?.bunnyMode = .off
                    self.synchronizeSettings()
                }
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("general.cancel", comment: ""), style: .cancel, handler: nil)
                
                controller.addAction(onAction)
                controller.addAction(offAction)
                controller.addAction(cancelAction)
                
                controller.popoverPresentationController?.sourceView = cell
                controller.popoverPresentationController?.sourceRect = cell.bounds
                
                present(controller, animated: true, completion: nil)
            }
        case .subscription:
            
            switch Info(rawValue: indexPath.row)! {
            case .community:
                guard let url = URL(string: "https://community.bunpro.jp/") else { return }
                
                present(customSafariViewController(url: url), animated: true)
            case .about:
                guard let url = URL(string: "https://bunpro.jp/about") else { return }
                
                present(customSafariViewController(url: url), animated: true)
            case .contact:
                guard let url = URL(string: "https://bunpro.jp/contact") else { return }
                
                present(customSafariViewController(url: url), animated: true)
            case .privacy:
                guard let url = URL(string: "https://bunpro.jp/privacy") else { return }
                
                present(customSafariViewController(url: url), animated: true)
            case .terms:
                guard let url = URL(string: "https://bunpro.jp/terms") else { return }
                
                present(customSafariViewController(url: url), animated: true)

            case .subscription, .empty: break
            }
            
        case .logout:
            switch indexPath.row {
            case 0:
                let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                let logoutAction = UIAlertAction(title: NSLocalizedString("settings.logout.action", comment: "Logout confirmation"), style: .destructive) { (_) in
                    Server.logout()
                    self.tabBarController?.selectedIndex = 0
                }
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("general.cancel", comment: ""), style: .cancel, handler: nil)
                
                controller.addAction(logoutAction)
                controller.addAction(cancelAction)
                
                controller.popoverPresentationController?.sourceView = cell
                controller.popoverPresentationController?.sourceRect = cell.bounds
                
                present(controller, animated: true, completion: nil)
            default: break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textColor = .white
        }
    }
        
    private func updateUI() {
        guard let account = self.account else {
            
            subscriptionDetailLabel.text = NSLocalizedString("subscription.unknown", comment: "The string that is displayed if the subscription state is not known, such as the user information is not yet updated.")
            return
        }
        
        subscriptionDetailLabel.text = account.subscriber ?
            NSLocalizedString("subscription.subscribed", comment: "the string that is displayed if the user is subscribed") :
        NSLocalizedString("subscription.unsubscribed", comment: "The string that is displayed if the user is not subscribed")
        
        guard let furigana = FuriganaMode(rawValue: account.furiganaMode ?? "") else { return }
        let english = account.englishMode ? Active.yes : Active.no
        let bunnyMode = account.bunnyMode ? State.on : State.off
        
        settings = SetSettingsProcedure.Settings(furigana: furigana, english: english, bunnyMode: bunnyMode)
    }
    
    private func synchronizeSettings() {
        guard let settings = settings else { return }
        let settingsProcedure = SetSettingsProcedure(presentingViewController: self, settings: settings) { (user, error) in
            guard let user = user, error == nil else {
                print(String(describing: error))
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
        
        let safariViewController = SFSafariViewController(url: url, configuration: configuration)
        
        safariViewController.preferredBarTintColor = .black
        safariViewController.preferredControlTintColor = UIColor(named: "Main Tint")
        
        return safariViewController
    }
}

extension Active {
    
    var localizedString: String {
        switch self {
        case .yes: return NSLocalizedString("active.yes", comment: "")
        case .no: return NSLocalizedString("active.no", comment: "")
        }
    }
}

extension State {
    
    var localizedString: String {
        switch self {
        case .on: return NSLocalizedString("state.on", comment: "")
        case .off: return NSLocalizedString("state.off", comment: "")
        }
    }
}

extension FuriganaMode {
    
    var localizedString: String {
        switch self {
        case .on: return NSLocalizedString("furigana.on", comment: "")
        case .off: return NSLocalizedString("furigana.off", comment: "")
        case .wanikani: return NSLocalizedString("furigana.wanikani", comment: "")
        }
    }
}
