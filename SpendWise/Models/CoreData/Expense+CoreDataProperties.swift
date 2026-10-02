//
//  Expense+CoreDataProperties.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-02.
//
//

public import Foundation
public import CoreData


public typealias ExpenseCoreDataPropertiesSet = NSSet

extension Expense {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }

    @NSManaged public var amount: Double
    @NSManaged public var budgetID: String?
    @NSManaged public var category: String?
    @NSManaged public var date: Date?
    @NSManaged public var expenseID: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var merchant: String?
    @NSManaged public var receiptData: Data?

}

extension Expense : Identifiable {

}
