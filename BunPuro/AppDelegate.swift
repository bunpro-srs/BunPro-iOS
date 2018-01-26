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
        
        center.requestAuthorization(options: [.sound, .alert]) { (granted, error) in
            guard error == nil else {
                
                print(error!)
                return
            }
            
            print(granted)
        }
        
        if let rootViewController = window?.rootViewController {
            dataManager = DataManager(presentingViewController: rootViewController)
        }
        
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

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
     
        completionHandler([.sound, .badge, .alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let statusViewController = (window?.rootViewController as? UITabBarController)?.viewControllers?.first(where: { $0 is StatusTableViewController }) as? StatusTableViewController
        
        statusViewController?.presentReviewViewController()
        
        completionHandler()
    }
}
