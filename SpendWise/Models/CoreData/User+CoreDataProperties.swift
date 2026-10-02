//
//  User+CoreDataProperties.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-02.
//
//

public import Foundation
public import CoreData


public typealias UserCoreDataPropertiesSet = NSSet

extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var email: String?
    @NSManaged public var name: String?
    @NSManaged public var userID: String?

}

extension User : Identifiable {

}
