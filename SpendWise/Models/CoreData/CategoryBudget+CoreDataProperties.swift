//
//  CategoryBudget+CoreDataProperties.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-02.
//
//

public import Foundation
public import CoreData


public typealias CategoryBudgetCoreDataPropertiesSet = NSSet

extension CategoryBudget {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryBudget> {
        return NSFetchRequest<CategoryBudget>(entityName: "CategoryBudget")
    }

    @NSManaged public var budgetID: String?
    @NSManaged public var category: String?
    @NSManaged public var limit: Double
    @NSManaged public var month: Int16

}

extension CategoryBudget : Identifiable {

}
