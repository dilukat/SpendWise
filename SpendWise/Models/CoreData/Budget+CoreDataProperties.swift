//
//  Budget+CoreDataProperties.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-02.
//
//

public import Foundation
public import CoreData


public typealias BudgetCoreDataPropertiesSet = NSSet

extension Budget {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Budget> {
        return NSFetchRequest<Budget>(entityName: "Budget")
    }

    @NSManaged public var budgetID: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var month: Int16
    @NSManaged public var totalAmount: Double
    @NSManaged public var userID: String?
    @NSManaged public var year: Int16

}

extension Budget : Identifiable {

}
