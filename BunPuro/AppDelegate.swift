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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        copyPredefinedDatabase()
        
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
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
        coreDataStack.save()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
        coreDataStack.save()
    }

    // Copy prepopulated database if needed
    private func copyPredefinedDatabase() {
        
        if let applicationSupportUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first, !FileManager.default.fileExists(atPath: applicationSupportUrl.path) {
            
            if
                let sqliteDestinationUrl = URL(string: applicationSupportUrl.absoluteString + modelName + ".sqlite"),
                let shmDestinationUrl = URL(string: applicationSupportUrl.absoluteString + modelName + ".sqlite-shm"),
                let walDestinationUrl = URL(string: applicationSupportUrl.absoluteString + modelName + ".sqlite-wal"),
                
                let sqliteSourceUrl = Bundle.main.url(forResource: modelName, withExtension: ".sqlite"),
                let shmSourceUrl = Bundle.main.url(forResource: modelName, withExtension: ".sqlite-shm"),
                let walSourceUrl = Bundle.main.url(forResource: modelName, withExtension: ".sqlite-wal") {
                
                do {
                    try FileManager.default.createDirectory(at: applicationSupportUrl, withIntermediateDirectories: true, attributes: nil)
                    try FileManager.default.copyItem(at: sqliteSourceUrl, to: sqliteDestinationUrl)
                    try FileManager.default.copyItem(at: shmSourceUrl, to: shmDestinationUrl)
                    try FileManager.default.copyItem(at: walSourceUrl, to: walDestinationUrl)
                } catch {
                    print(error)
                }
            }
        }
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
