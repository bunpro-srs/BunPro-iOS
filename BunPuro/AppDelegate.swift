//
//  AppDelegate.swift
//  BunPuro
//
//  Created by Andreas Braun on 26.10.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import BunPuroKit
import UserNotifications
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    static var coreDataStack: CoreDataStack {
        return (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    }
    
    private var modelName = "BunPro"
    lazy var coreDataStack = CoreDataStack(modelName: modelName)
    
    private var dataManager: DataManager?
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Server.reset()
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.requestAuthorization(options: [.badge, .sound, .alert]) { (granted, error) in
            guard error == nil else {
                
                print(error!)
                return
            }
            
            print(granted)
        }
        
        if let rootViewController = window?.rootViewController {
            dataManager = DataManager(presentingViewController: rootViewController)
        }
        
        //UserNotificationCenter.shared.scheduleNextReviewNotification(at: Date().addingTimeInterval(10))
        
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
        dataManager?.startStatusUpdates()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        dataManager?.startStatusUpdates()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        coreDataStack.save()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
        coreDataStack.save()
    }
    
    static func setNeedsStatusUpdate() {
        (UIApplication.shared.delegate as? AppDelegate)?.dataManager?.immidiateStatusUpdate()
    }
    
    static var isUpdating: Bool {
        return (UIApplication.shared.delegate as? AppDelegate)?.dataManager?.isUpdating ?? false
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
