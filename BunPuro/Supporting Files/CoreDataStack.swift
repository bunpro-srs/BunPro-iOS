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
        return self.storeContainer.viewContext
    }()
    
    public init(modelName: String) {
        self.modelName = modelName
    }
    
    private lazy var storeContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error: \(error.userInfo)")
            }
        }
        
        return container
    }()
    
    public func newBackgroundContext() -> NSManagedObjectContext {
        return self.storeContainer.newBackgroundContext()
    }
    
    public func save() {
        guard managedObjectContext.hasChanges else { return }
        
        do {
            try managedObjectContext.save()
        } catch let error as NSError {
            print("Unresolved error: \(error.userInfo)")
        }
    }
    
}
