//
//  AppDelegate.swift
//  CreateDatabase
//
//  Created by Andreas Braun on 26.01.18.
//  Copyright © 2018 Andreas Braun. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private var modelName = "BunPro"
    lazy var coreDataStack = CoreDataStack(modelName: modelName)
    
    static var coreDataStack: CoreDataStack {
        return (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}

