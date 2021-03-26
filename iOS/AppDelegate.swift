//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import BunProKit
import Combine
import CoreData
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? {
        didSet { window?.tintColor = Asset.tint.color }
    }

    static var database: Database { (UIApplication.shared.delegate as! AppDelegate).database }
    static var dataManager: DataManager? {
        get { (UIApplication.shared.delegate as! AppDelegate).dataManager }
        set { (UIApplication.shared.delegate as! AppDelegate).dataManager = newValue }
    }

    private var modelName: String = "BunPro"
    lazy var database = Database(modelName: modelName)

    private var dataManager: DataManager?

    private var subscriptions = Set<AnyCancellable>()

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Logger.shared.setup()

        UserDefaults.standard
            .publisher(for: \.userInterfaceStyle, options: [.initial, .new])
            .receive(on: RunLoop.main)
            .sink { userInterfaceStyle in
                application.windows.forEach { window in
                    window.overrideUserInterfaceStyle = userInterfaceStyle.systemStyle
                }
            }
            .store(in: &subscriptions)

        return true
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Server.reset()

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.badge, .sound, .alert, .provisional]) { _, error in
            guard error == nil else {
                log.error(error!)
                return
            }
        }

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        database.save()
    }

    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
//        if let type = NSUserActivity.ActivityType(rawValue: userActivityType) {
//            guard let tabbarController = self.window?.rootViewController as? UITabBarController else { return false }
//                tabbarController.selectedIndex = 0
//
//            guard let viewCtrl = tabbarController.viewControllers?.first?.content else { return false }
//
//            switch viewCtrl {
//            case is DashboardTableViewController:
//                let statusViewCtrl = viewCtrl as? DashboardTableViewController
//
//                switch type {
//                case .study:
//                    statusViewCtrl?.presentReviewViewController(website: .study)
//
//                case .cram:
//                    statusViewCtrl?.presentReviewViewController(website: .cram)
//                }
//
//            case is ReviewViewController:
//                let reviewViewCtrl = viewCtrl as? ReviewViewController
//
//                switch type {
//                case .study:
//                    reviewViewCtrl?.website = .study
//
//                case .cram:
//                    reviewViewCtrl?.website = .cram
//                }
//
//            default:
//                return false
//            }
//        }

        return false
    }

    static func setNeedsStatusUpdate() {
        (UIApplication.shared.delegate as? AppDelegate)?.dataManager?.immidiateStatusUpdate()
    }

    static var isContentAccessable: Bool { Account.currentAccount?.subscriber ?? false }

    static var numberOfAllowedSentences: Int { isContentAccessable ? Int.max : 1 }

    static func modifyReview(_ modificationType: ModifyReviewProcedure.ModificationType) {
        (UIApplication.shared.delegate as? AppDelegate)?.dataManager?.modifyReview(modificationType)
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
//        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
//            let statusViewCtrl = (window?.rootViewController as? UITabBarController)?
//                .viewControllers?
//                .first { $0 is DashboardTableViewController } as? DashboardTableViewController
//
//            statusViewCtrl?.showReviewsOnViewDidAppear = true
//        }

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
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = AppDelegate.badgeNumber()?.intValue ?? 0
        }
    }
}
