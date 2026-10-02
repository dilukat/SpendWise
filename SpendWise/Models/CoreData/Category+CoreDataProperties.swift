//
//  Category+CoreDataProperties.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-02.
//
//

public import Foundation
public import CoreData


public typealias CategoryCoreDataPropertiesSet = NSSet

extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var categoryID: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var icon: String?
    @NSManaged public var name: String?

}

extension Category : Identifiable {

}
