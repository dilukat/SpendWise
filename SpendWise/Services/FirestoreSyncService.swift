//
//  FirestoreSyncService.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-21.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import CoreData

@MainActor
final class FirestoreSyncService {

    static let shared = FirestoreSyncService()

    private let db = Firestore.firestore()

    private init() {}
    
    func uploadExpense(_ expense: Expense) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Please log in before syncing expenses."
                ]
            )
        }

        guard let expenseID = expense.expenseID,
              !expenseID.isEmpty else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "The expense ID is missing."
                ]
            )
        }

        guard expense.userID == userID else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 403,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "This expense does not belong to the current user."
                ]
            )
        }

        var data: [String: Any] = [
            "expenseID": expenseID,
            "userID": userID,
            "amount": expense.amount,
            "category": expense.category ?? "Other",
            "merchant": expense.merchant ?? "",
            "latitude": expense.latitude,
            "longitude": expense.longitude
        ]

        if let date = expense.date {
            data["date"] = Timestamp(date: date)
        }

        if let budgetID = expense.budgetID {
            data["budgetID"] = budgetID
        }

        if let receiptData = expense.receiptData {
            data["receiptData"] = receiptData.base64EncodedString()
        }

        try await db
            .collection("users")
            .document(userID)
            .collection("expenses")
            .document(expenseID)
            .setData(data, merge: true)
    }
    
    func uploadPendingExpenses() async throws -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Please log in before syncing expenses."
                ]
            )
        }

        let context = CoreDataService.shared.viewContext

        let request = NSFetchRequest<Expense>(
            entityName: "Expense"
        )

        request.predicate = NSPredicate(
            format: "userID == %@ AND isSynced == NO AND isPendingDeletion == NO",
            userID
        )

        let pendingExpenses = try context.fetch(request)
        var uploadedCount = 0

        for expense in pendingExpenses {
            guard Auth.auth().currentUser?.uid == userID else {
                break
            }

            do {
                try await uploadExpense(expense)

                guard Auth.auth().currentUser?.uid == userID else {
                    break
                }

                expense.isSynced = true
                try context.save()
                uploadedCount += 1

                print("Pending expense uploaded: \(expense.expenseID ?? "Unknown")")
            } catch {
                print(
                    "Pending expense upload failed: \(error.localizedDescription)"
                )
            }
        }

        print("Pending expense sync finished. Uploaded: \(uploadedCount)")
        return uploadedCount
    }
    
    
    func deleteExpenseFromFirestore(_ expense: Expense) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Please log in before deleting an expense."
                ]
            )
        }

        guard let expenseID = expense.expenseID,
              !expenseID.isEmpty,
              expense.userID == userID else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 403,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "This expense cannot be deleted for the current user."
                ]
            )
        }

        try await db
            .collection("users")
            .document(userID)
            .collection("expenses")
            .document(expenseID)
            .delete()

        print("Expense deleted from Firestore: \(expenseID)")
    }

    func syncPendingExpenseDeletions() async throws -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Please log in before syncing pending deletions."
                ]
            )
        }

        let context = CoreDataService.shared.viewContext
        let request = NSFetchRequest<Expense>(entityName: "Expense")

        request.predicate = NSPredicate(
            format: "userID == %@ AND isPendingDeletion == YES",
            userID
        )

        let pendingDeletions = try context.fetch(request)
        var deletedCount = 0

        for expense in pendingDeletions {
            // Never continue syncing if the account changes.
            guard Auth.auth().currentUser?.uid == userID else {
                print("Account changed; stopping pending-deletion sync.")
                break
            }

            do {
                // Firestore deletion is safe to retry if the document
                // has already been deleted.
                try await deleteExpenseFromFirestore(expense)

                // Check ownership again before modifying local data.
                guard Auth.auth().currentUser?.uid == userID,
                      expense.userID == userID else {
                    print("Account changed; pending deletion retained.")
                    break
                }

                context.delete(expense)
                try context.save()

                deletedCount += 1
                print(
                    "Pending expense deletion synced: \(expense.expenseID ?? "Unknown")"
                )

            } catch {
                // Keep the record marked for deletion so it can retry.
                print(
                    "Pending deletion failed: \(error.localizedDescription)"
                )
            }
        }

        print("Pending deletion sync finished. Deleted: \(deletedCount)")
        return deletedCount
    }


    func downloadExpenses() async throws -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Please log in before downloading expenses."
                ]
            )
        }

        let snapshot = try await db
            .collection("users")
            .document(userID)
            .collection("expenses")
            .getDocuments()

        let context = CoreDataService.shared.viewContext

        let request = NSFetchRequest<Expense>(
            entityName: "Expense"
        )
        request.predicate = NSPredicate(
            format: "userID == %@",
            userID
        )

        let localExpenses = try context.fetch(request)

        var expensesByID: [String: Expense] = [:]

        for expense in localExpenses {
            if let expenseID = expense.expenseID {
                expensesByID[expenseID] = expense
            }
        }

        var downloadedCount = 0

        for document in snapshot.documents {
            
            let data = document.data()

            guard
                let expenseID = data["expenseID"] as? String,
                let recordUserID = data["userID"] as? String,
                let amount = (data["amount"] as? NSNumber)?.doubleValue,
                SyncedExpenseValidator.validate(
                    expenseID: expenseID,
                    userID: recordUserID,
                    expectedUserID: userID,
                    amount: amount
                )
            else {
                print("Skipping invalid expense: \(document.documentID)")
                continue
            }


            // Update an existing record or create a new one.
            let expense = expensesByID[expenseID]
                ?? Expense(context: context)

            expense.expenseID = expenseID
            expense.userID = userID
            expense.amount = amount
            expense.category = data["category"] as? String ?? "Other"
            expense.merchant = data["merchant"] as? String ?? ""

            if let timestamp = data["date"] as? Timestamp {
                expense.date = timestamp.dateValue()
            }

            if let budgetID = data["budgetID"] as? String {
                expense.budgetID = budgetID
            } else {
                expense.budgetID = nil
            }

            expense.latitude =
                (data["latitude"] as? NSNumber)?.doubleValue ?? 0

            expense.longitude =
                (data["longitude"] as? NSNumber)?.doubleValue ?? 0

            if let receiptString = data["receiptData"] as? String {
                expense.receiptData = Data(
                    base64Encoded: receiptString
                )
            } else {
                expense.receiptData = nil
            }

            expensesByID[expenseID] = expense
            downloadedCount += 1
        }

        if context.hasChanges {
            try context.save()
        }

        print("Downloaded or updated \(downloadedCount) expenses from Firestore.")
        return downloadedCount
    }

    
    func uploadBudget(_ budget: Budget) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Please log in before syncing budgets."
                ]
            )
        }

        guard budget.userID == userID else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 403,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "This budget does not belong to the current user."
                ]
            )
        }

        guard let budgetID = budget.budgetID,
              !budgetID.isEmpty else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "The budget ID is missing."
                ]
            )
        }

        var data: [String: Any] = [
            "budgetID": budgetID,
            "userID": userID,
            "month": Int(budget.month),
            "year": Int(budget.year),
            "totalAmount": budget.totalAmount
        ]

        if let createdDate = budget.createdDate {
            data["createdDate"] = Timestamp(date: createdDate)
        }

        try await db
            .collection("users")
            .document(userID)
            .collection("budgets")
            .document(budgetID)
            .setData(data, merge: true)
    }
    
    
    func uploadLocalBudgetsAndCategoryBudgets() async throws -> (budgets: Int, categoryBudgets: Int) {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Please log in before syncing budgets."
                ]
            )
        }

        let context = CoreDataService.shared.viewContext

        // Fetch only the current user's monthly budgets.
        let budgetRequest = NSFetchRequest<Budget>(
            entityName: "Budget"
        )
        budgetRequest.predicate = NSPredicate(
            format: "userID == %@",
            userID
        )

        let localBudgets = try context.fetch(budgetRequest)

        var budgetsByID: [String: Budget] = [:]
        var uploadedBudgets = 0

        // Upload monthly budgets first.
        for budget in localBudgets {
            guard Auth.auth().currentUser?.uid == userID else {
                throw NSError(
                    domain: "FirestoreSyncService",
                    code: 403,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Account changed during budget synchronization."
                    ]
                )
            }

            guard let budgetID = budget.budgetID,
                  !budgetID.isEmpty else {
                print("Skipping budget with a missing ID.")
                continue
            }

            try await uploadBudget(budget)
            budgetsByID[budgetID] = budget
            uploadedBudgets += 1
        }

        // Fetch category budgets belonging to those monthly budgets.
        let budgetIDs = Array(budgetsByID.keys)

        guard !budgetIDs.isEmpty else {
            print("No local budgets found for the current user.")
            return (uploadedBudgets, 0)
        }

        let categoryRequest = NSFetchRequest<CategoryBudget>(
            entityName: "CategoryBudget"
        )
        categoryRequest.predicate = NSPredicate(
            format: "budgetID IN %@",
            budgetIDs
        )

        let localCategoryBudgets = try context.fetch(categoryRequest)
        var uploadedCategoryBudgets = 0

        for categoryBudget in localCategoryBudgets {
            guard Auth.auth().currentUser?.uid == userID else {
                throw NSError(
                    domain: "FirestoreSyncService",
                    code: 403,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Account changed during category budget synchronization."
                    ]
                )
            }

            guard let budgetID = categoryBudget.budgetID,
                  let monthlyBudget = budgetsByID[budgetID] else {
                print("Skipping category budget without a matching monthly budget.")
                continue
            }

            try await uploadCategoryBudget(
                categoryBudget,
                monthlyBudget: monthlyBudget
            )

            uploadedCategoryBudgets += 1
        }

        print("Monthly budgets uploaded: \(uploadedBudgets)")
        print("Category budgets uploaded: \(uploadedCategoryBudgets)")

        return (uploadedBudgets, uploadedCategoryBudgets)
    }

    
    func downloadBudgets() async throws -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Please log in before downloading budgets."
                ]
            )
        }

        let snapshot = try await db
            .collection("users")
            .document(userID)
            .collection("budgets")
            .getDocuments()

        let context = CoreDataService.shared.viewContext

        let request = NSFetchRequest<Budget>(
            entityName: "Budget"
        )
        request.predicate = NSPredicate(
            format: "userID == %@",
            userID
        )

        let localBudgets = try context.fetch(request)

        var budgetsByID: [String: Budget] = [:]

        for budget in localBudgets {
            if let budgetID = budget.budgetID {
                budgetsByID[budgetID] = budget
            }
        }

        var downloadedCount = 0

        for document in snapshot.documents {
            let data = document.data()

            guard
                let budgetID = data["budgetID"] as? String,
                !budgetID.isEmpty,
                let recordUserID = data["userID"] as? String,
                recordUserID == userID,
                let monthValue = data["month"] as? NSNumber,
                let yearValue = data["year"] as? NSNumber,
                let amountValue = data["totalAmount"] as? NSNumber
            else {
                print("Skipping invalid budget: \(document.documentID)")
                continue
            }

            let month = monthValue.intValue
            let year = yearValue.intValue
            let amount = amountValue.doubleValue

            guard
                (1...12).contains(month),
                (1...9999).contains(year),
                amount.isFinite,
                amount > 0
            else {
                print("Skipping budget with invalid values: \(budgetID)")
                continue
            }

            let budget = budgetsByID[budgetID]
                ?? Budget(context: context)

            budget.budgetID = budgetID
            budget.userID = userID
            budget.month = Int16(month)
            budget.year = Int16(year)
            budget.totalAmount = amount

            if let timestamp = data["createdDate"] as? Timestamp {
                budget.createdDate = timestamp.dateValue()
            }

            budgetsByID[budgetID] = budget
            downloadedCount += 1
        }

        if context.hasChanges {
            try context.save()
        }

        print(
            "Downloaded or updated \(downloadedCount) budgets from Firestore."
        )

        return downloadedCount
    }
    
    func uploadCategoryBudget(
        _ categoryBudget: CategoryBudget,
        monthlyBudget: Budget
    ) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Please log in before syncing category budgets."
                ]
            )
        }

        guard monthlyBudget.userID == userID else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 403,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "This monthly budget does not belong to the current user."
                ]
            )
        }

        guard
            let budgetID = monthlyBudget.budgetID,
            !budgetID.isEmpty,
            categoryBudget.budgetID == budgetID,
            let category = categoryBudget.category,
            !category.isEmpty
        else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "The category budget details are incomplete."
                ]
            )
        }

        let encodedCategory = category.addingPercentEncoding(
            withAllowedCharacters: .alphanumerics
        ) ?? category

        let documentID = "\(budgetID)_\(encodedCategory)"

        let data: [String: Any] = [
            "budgetID": budgetID,
            "userID": userID,
            "category": category,
            "limit": categoryBudget.limit,
            "month": Int(categoryBudget.month)
        ]

        try await db.collection("users")
            .document(userID)
            .collection("categoryBudgets")
            .document(documentID)
            .setData(data, merge: true)
    }
    
    func downloadCategoryBudgets() async throws -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "FirestoreSyncService",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Please log in before downloading category budgets."
                ]
            )
        }

        let snapshot = try await db
            .collection("users")
            .document(userID)
            .collection("categoryBudgets")
            .getDocuments()

        let context = CoreDataService.shared.viewContext

        let request = NSFetchRequest<CategoryBudget>(
            entityName: "CategoryBudget"
        )

        request.predicate = NSPredicate(
            format: "budgetID IN %@",
            (try context.fetch(
                NSFetchRequest<Budget>(entityName: "Budget")
            ))
            .filter { $0.userID == userID }
            .compactMap { $0.budgetID }
        )

        let localCategoryBudgets = try context.fetch(request)

        var categoryBudgetsByKey: [String: CategoryBudget] = [:]

        for categoryBudget in localCategoryBudgets {
            if let budgetID = categoryBudget.budgetID,
               let category = categoryBudget.category {
                categoryBudgetsByKey["\(budgetID)|\(category)"] = categoryBudget
            }
        }

        var downloadedCount = 0

        for document in snapshot.documents {
            
            let data = document.data()

            guard
                let budgetID = data["budgetID"] as? String,
                let recordUserID = data["userID"] as? String,
                let category = data["category"] as? String,
                let limitValue = data["limit"] as? NSNumber,
                let monthValue = data["month"] as? NSNumber,
                SyncedCategoryBudgetValidator.validate(
                    budgetID: budgetID,
                    userID: recordUserID,
                    expectedUserID: userID,
                    category: category,
                    limit: limitValue.doubleValue,
                    month: monthValue.intValue
                )
            else {
                print("Skipping invalid category budget: \(document.documentID)")
                continue
            }


            // Only attach category budgets to this user's existing monthly budget.
            let monthlyBudgetRequest = NSFetchRequest<Budget>(
                entityName: "Budget"
            )
            monthlyBudgetRequest.fetchLimit = 1
            monthlyBudgetRequest.predicate = NSPredicate(
                format: "budgetID == %@ AND userID == %@",
                budgetID,
                userID
            )

            guard let monthlyBudget = try context.fetch(
                monthlyBudgetRequest
            ).first else {
                print("Skipping category budget with no local monthly budget: \(budgetID)")
                continue
            }

            let limit = limitValue.doubleValue
            let month = monthValue.intValue

            guard limit.isFinite, limit > 0, (1...12).contains(month) else {
                print("Skipping category budget with invalid values: \(document.documentID)")
                continue
            }

            let key = "\(budgetID)|\(category)"
            let categoryBudget = categoryBudgetsByKey[key]
                ?? CategoryBudget(context: context)

            categoryBudget.budgetID = monthlyBudget.budgetID
            categoryBudget.category = category
            categoryBudget.limit = limit
            categoryBudget.month = Int16(month)

            categoryBudgetsByKey[key] = categoryBudget
            downloadedCount += 1
        }

        if context.hasChanges {
            try context.save()
        }

        print(
            "Downloaded or updated \(downloadedCount) category budgets from Firestore."
        )

        return downloadedCount
    }


}

