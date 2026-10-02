//
//  CoreDataService.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-02.
//

import Foundation
import CoreData

final class CoreDataService {
    
    static let shared = CoreDataService()
    let container: NSPersistentContainer
    
    private init() {
        
        container = NSPersistentContainer(name: "SpendWise")
        
        container.loadPersistentStores { _, error in

                    if let error = error {

                        fatalError(
                            "Unable to load Core Data: \(error)"
                        )
                    }
                }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    func saveContext() {
        
        let context = container.viewContext
        
        guard context.hasChanges else {
            return
        }
        
        do{
            
            try context.save()
            
        } catch {
            
            print("Core Data save error: \(error.localizedDescription)")
        }
    }
}
