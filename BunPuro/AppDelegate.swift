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
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert]) { (granted, error) in
            guard error == nil else {
                
                print(error!)
                return
            }
            
            print(granted)
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        coreDataStack.save()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
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

