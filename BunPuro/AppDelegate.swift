//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import BunPuroKit
import CoreData
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    static var coreDataStack: CoreDataStack {
        return (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    }

    private var modelName = "BunPro"
    lazy var coreDataStack = CoreDataStack(modelName: modelName)

    private var dataManager: DataManager?

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = UIColor(named: "NavigationBarHeader")

        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().barTintColor = UIColor(named: "NavigationBarHeader")

        CorneredView.appearance().backgroundColor = UIColor(named: "Tiles")
        UITableViewCell.appearance().clipsToBounds = true
        UITableViewCell.appearance().contentView.clipsToBounds = true

        UIProgressView.appearance().trackTintColor = UIColor(named: "Background")
        UIProgressView.appearance().progressTintColor = UIColor(named: "TilesSymbol")

        window?.tintColor = UIColor(named: "Main Tint")

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

        Server.reset()

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.badge, .sound, .alert]) { _, error in
            guard error == nil else {
                print(error!)
                return
            }
        }

        if let rootViewController = window?.rootViewController {
            dataManager = DataManager(presentingViewController: rootViewController)
        }

//        UserNotificationCenter.shared.scheduleNextReviewNotification(at: Date().addingTimeInterval(20))
//        UserNotificationCenter.shared.scheduleNextReviewNotification(at: Date().addingTimeInterval(25))

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        dataManager?.startStatusUpdates()
    }

    func applicationWillResignActive(_ application: UIApplication) {
//        dataManager?.startStatusUpdates()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        coreDataStack.save()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        coreDataStack.save()
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

            guard let viewController = tabbarController.viewControllers?.first?.content else { return false }

            switch viewController {
            case is StatusTableViewController:

                let statusViewController = viewController as? StatusTableViewController

                switch type {
                case .study:
                    statusViewController?.presentReviewViewController(website: .study)

                case .cram:
                    statusViewController?.presentReviewViewController(website: .cram)
                }

            case is ReviewViewController:
                let reviewViewController = viewController as? ReviewViewController

                switch type {
                case .study:
                    reviewViewController?.website = .study

                case .cram:
                    reviewViewController?.website = .cram
                }
            default: return false
            }
        }

        return false
    }

    static func setNeedsStatusUpdate() {
        (UIApplication.shared.delegate as? AppDelegate)?.dataManager?.immidiateStatusUpdate()
    }

    static func signupForTrial() {
        (UIApplication.shared.delegate as? AppDelegate)?.dataManager?.signupForTrial()
    }

    static func signup() {
        (UIApplication.shared.delegate as? AppDelegate)?.dataManager?.signup()
    }

    static var isUpdating: Bool {
        return (UIApplication.shared.delegate as? AppDelegate)?.dataManager?.isUpdating ?? false
    }

    static var isTrialPeriodAvailable: Bool {
        let hasBegun = Date() > Date(day: 10, month: 5, year: 2_018)
        let hasEnded = Date() > Date(day: 11, month: 6, year: 2_018)
        return hasBegun && !hasEnded
    }

    static var isContentAccessable: Bool {
        guard Date() > Date(day: 10, month: 5, year: 2_018) else { return true }
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
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        UserNotificationCenter.shared.updateNotifications(basedOnReceived: notification)

        completionHandler([.sound, .badge, .alert])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            let statusViewController = (window?.rootViewController as? UITabBarController)?.viewControllers?.first(where: { $0 is StatusTableViewController }) as? StatusTableViewController

            statusViewController?.showReviewsOnViewDidAppear = true
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
            let reviews = try AppDelegate.coreDataStack.storeContainer.viewContext.fetch(fetchRequest)

            return NSNumber(value: reviews.count)
        } catch {
            print(error)

            return nil
        }
    }

    static func updateAppBadgeIcon() {
        UIApplication.shared.applicationIconBadgeNumber = AppDelegate.badgeNumber()?.intValue ?? 0
    }
}
