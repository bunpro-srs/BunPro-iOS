//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import BunProKit
import CoreData
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? {
        didSet { window?.tintColor = Asset.tint.color }
    }

    static var database: Database {
        return (UIApplication.shared.delegate as! AppDelegate).database
    }

    private var modelName: String = "BunPro"
    lazy var database = Database(modelName: modelName)

    private var dataManager: DataManager?
    private var appearanceObservation: NSKeyValueObservation?

    deinit {
        appearanceObservation?.invalidate()
    }

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Logger.shared.setup()

        setupTabBarViewController()

        if #available(iOS 13.0, *) {
            appearanceObservation = UserDefaults
                .standard
                .observe(\.userInterfaceStyle, options: [.initial, .new]) { defaults, _ in
                    application.windows.forEach { window in
                        window.overrideUserInterfaceStyle = defaults.userInterfaceStyle.systemStyle
                    }
                }
        }

        return true
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Server.reset()

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.badge, .sound, .alert]) { _, error in
            guard error == nil else {
                log.error(error!)
                return
            }
        }

        if let rootViewCtrl = window?.rootViewController {
            dataManager = DataManager(presentingViewController: rootViewCtrl, database: database)
        }

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        dataManager?.startStatusUpdates()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        database.save()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        database.save()
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let dataManager = dataManager {
            dataManager.scheduleUpdateProcedure(completion: completionHandler)
        } else {
            completionHandler(.failed)
        }
    }

    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        if let type = NSUserActivity.ActivityType(rawValue: userActivityType) {
            guard let tabbarController = self.window?.rootViewController as? UITabBarController else { return false }
                tabbarController.selectedIndex = 0

            guard let viewCtrl = tabbarController.viewControllers?.first?.content else { return false }

            switch viewCtrl {
            case is StatusTableViewController:
                let statusViewCtrl = viewCtrl as? StatusTableViewController

                switch type {
                case .study:
                    statusViewCtrl?.presentReviewViewController(website: .study)

                case .cram:
                    statusViewCtrl?.presentReviewViewController(website: .cram)
                }

            case is ReviewViewController:
                let reviewViewCtrl = viewCtrl as? ReviewViewController

                switch type {
                case .study:
                    reviewViewCtrl?.website = .study

                case .cram:
                    reviewViewCtrl?.website = .cram
                }

            default:
                return false
            }
        }

        return false
    }

    static func setNeedsStatusUpdate() {
        (UIApplication.shared.delegate as? AppDelegate)?.dataManager?.immidiateStatusUpdate()
    }

    static var isContentAccessable: Bool {
        return Account.currentAccount?.subscriber ?? false
    }

    static var numberOfAllowedSentences: Int {
        if isContentAccessable {
            return Int.max
        } else {
            return 1
        }
    }

    static func modifyReview(_ modificationType: ModifyReviewProcedure.ModificationType) {
        (UIApplication.shared.delegate as? AppDelegate)?.dataManager?.modifyReview(modificationType)
    }

    private func setupTabBarViewController() {
        guard let viewControllers = (window?.rootViewController as? UITabBarController)?.viewControllers else { return }
        for (index, viewController) in viewControllers.enumerated() {
            if #available(iOS 13.0, *) {
                switch index {
                case 0:
                    viewController.tabBarItem = UITabBarItem(
                        title: L10n.Tabbar.status,
                        image: .pencilCircle,
                        selectedImage: .pencilCircleFill
                    )

                case 1:
                    viewController.tabBarItem = UITabBarItem(
                        title: L10n.Tabbar.search,
                        image: .magnifyingglassCircle,
                        selectedImage: .magnifyingglassCircleFill
                    )

                case 2:
                    viewController.tabBarItem = UITabBarItem(
                        title: L10n.Tabbar.settings,
                        image: .ellipsisCircle,
                        selectedImage: .ellipsisCircleFill
                    )

                default:
                    break
                }
            } else {
                switch index {
                case 0:
                    viewController.tabBarItem = UITabBarItem(
                        title: L10n.Tabbar.status,
                        image: Asset.tabDashboardInactive.image,
                        selectedImage: Asset.tabDashboardActive.image
                    )

                case 1:
                    viewController.tabBarItem = UITabBarItem(
                        title: L10n.Tabbar.search,
                        image: Asset.tabSearchInactive.image,
                        selectedImage: Asset.tabSearchActive.image
                    )

                case 2:
                    viewController.tabBarItem = UITabBarItem(
                        title: L10n.Tabbar.settings,
                        image: Asset.tabSettingsInactive.image,
                        selectedImage: Asset.tabSettingsActive.image
                    )

                default:
                    break
                }
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        UserNotificationCenter.shared.updateNotifications(basedOnReceived: notification)
        completionHandler([.sound, .badge, .alert])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            let statusViewCtrl = (window?.rootViewController as? UITabBarController)?
                .viewControllers?
                .first { $0 is StatusTableViewController } as? StatusTableViewController

            statusViewCtrl?.showReviewsOnViewDidAppear = true
        }

        completionHandler()
    }

    static func resetAppBadgeIcon() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    static func badgeNumber(date: Date = Date()) -> NSNumber? {
        let fetchRequest: NSFetchRequest<Review> = Review.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K <= %@ && complete = true", #keyPath(Review.nextReviewDate), date as NSDate)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Review.identifier), ascending: true)
        ]

        do {
            let reviews = try AppDelegate.database.viewContext.fetch(fetchRequest)
            return NSNumber(value: reviews.count)
        } catch {
            log.error(error)
            return nil
        }
    }

    static func updateAppBadgeIcon() {
        UIApplication.shared.applicationIconBadgeNumber = AppDelegate.badgeNumber()?.intValue ?? 0
    }
}
