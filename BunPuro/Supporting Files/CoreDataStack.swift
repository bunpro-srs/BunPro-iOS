//
//  CoreDataStack.swift
//  BunPuro
//
//  Created by Andreas Braun on 08.11.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataStack {
    
    private let modelName: String
    
    public lazy var managedObjectContext: NSManagedObjectContext = {
        self.storeContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        self.storeContainer.viewContext.automaticallyMergesChangesFromParent = true
        return self.storeContainer.viewContext
    }()
    
    public init(modelName: String) {
        self.modelName = modelName
    }
    
    public lazy var storeContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: NSPersistentContainer.defaultDirectoryURL().path)
                    
                    for name in contents {
                        
                        if let url = URL(string: NSPersistentContainer.defaultDirectoryURL().absoluteString + name) {
                            try FileManager.default.removeItem(at: url)
                        }
                    }
                    
                    container.loadPersistentStores { (desc, error) in
                        if let error = error as NSError? {
                            print("Unresolved error: \(error.userInfo)")
                        }
                    }
                } catch let fileError {
                    print("Unresolved error: \(error.userInfo)\n\(fileError)")
                }
            }
        }
        
        return container
    }()
    
    public func save() {
        guard managedObjectContext.hasChanges else { return }
        
        do {
            try managedObjectContext.save()
        } catch let error as NSError {
            print("Unresolved error: \(error.userInfo)")
        }
    }
}
