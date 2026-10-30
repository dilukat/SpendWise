//
//  ExpenseViewModel.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-09.
//

import Foundation
internal import Combine
internal import CoreData
import FirebaseAuth

final class ExpenseViewModel: ObservableObject {

    @Published var amount = ""
    @Published var category = "Food"
    @Published var merchant = ""
    
    @Published var receiptData: Data?
    
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0

    @Published var errorMessage = ""
    @Published var showSuccessMessage = false
    @Published var expenses: [Expense] = []

    let categories = [
        "Food",
        "Transport",
        "Shopping",
        "Bills",
        "Entertainment",
        "Health",
        "Other"
    ]
    
    init(shouldFetchOnInit: Bool = true) {
        if shouldFetchOnInit {
            fetchExpenses()
        }
    }
    
    func saveExpense() {
        if let validationError = ExpenseValidator.validateAmount(amount) {
                errorMessage = validationError
                return
        }

        guard let expenseAmount = Double(amount) else {
            return
        }

        guard let userID = FirebaseService.shared.currentUser?.uid else {
            errorMessage = "Please log in to save an expense."
            return
        }

        let context = CoreDataService.shared.viewContext
        let expense = Expense(context: context)

        expense.userID = userID
        expense.isSynced = false
        expense.expenseID = UUID().uuidString
        expense.amount = expenseAmount
        expense.category = category
        expense.merchant = merchant
        expense.date = Date()
        expense.budgetID = ""
        expense.receiptData = receiptData
        expense.latitude = latitude
        expense.longitude = longitude

        // Save locally first.
        CoreDataService.shared.saveContext()

        // Keep a reference to the newly created expense for cloud sync.
        let savedExpense = expense

        // Reset the form.
        amount = ""
        merchant = ""
        receiptData = nil
        latitude = 0
        longitude = 0

        errorMessage = ""
        showSuccessMessage = true

        fetchExpenses()
        checkCurrentMonthBudgetAlert()

        print("Expense saved locally.")

        // Upload the expense to Firestore.
        Task { @MainActor in
            do {
                try await FirestoreSyncService.shared.uploadExpense(savedExpense)

                savedExpense.isSynced = true
                CoreDataService.shared.saveContext()

                print("Expense synced to Firestore.")
            } catch {
                print("Expense cloud sync failed: \(error.localizedDescription)")
            }
        }    }
    
    
//    func deleteExpense(_ expense: Expense) {
//        guard let userID = FirebaseService.shared.currentUser?.uid,
//              expense.userID == userID else {
//            errorMessage = "You can only delete your own expenses."
//            return
//        }
//
//        Task { @MainActor in
//            do {
//                try await FirestoreSyncService.shared
//                    .deleteExpenseFromFirestore(expense)
//
//                let context = CoreDataService.shared.viewContext
//                context.delete(expense)
//                CoreDataService.shared.saveContext()
//
//                fetchExpenses()
//                checkCurrentMonthBudgetAlert()
//
//                print("Expense deleted successfully from local and cloud storage.")
//            } catch {
//                errorMessage = "Could not delete expense from cloud: \(error.localizedDescription)"
//                print("Expense deletion failed: \(error.localizedDescription)")
//            }
//        }
//    }
    
    func deleteExpense(_ expense: Expense) {
        guard let userID = FirebaseService.shared.currentUser?.uid,
              expense.userID == userID else {
            errorMessage = "You can only delete your own expenses."
            return
        }

        let context = CoreDataService.shared.viewContext

        // Mark the expense for deletion before contacting Firestore.
        expense.isPendingDeletion = true

        do {
            try context.save()
        } catch {
            expense.isPendingDeletion = false
            errorMessage = "Could not save the deletion request."
            print("Failed to mark expense for deletion: \(error.localizedDescription)")
            return
        }

        // Hide the pending deletion from the History screen.
        fetchExpenses()

        Task { @MainActor in
            do {
                try await FirestoreSyncService.shared
                    .deleteExpenseFromFirestore(expense)

                // Do not modify local data if the account changed.
                guard FirebaseService.shared.currentUser?.uid == userID else {
                    print("Account changed; pending deletion retained.")
                    return
                }

                context.delete(expense)
                try context.save()

                fetchExpenses()
                checkCurrentMonthBudgetAlert()

                errorMessage = ""
                print("Expense deleted from local and cloud storage.")

            } catch {
                // Keep the record for a future deletion retry.
                errorMessage = "Deletion is pending until synchronization succeeds."
                print("Expense deletion pending: \(error.localizedDescription)")
            }
        }
    }


    
//    func fetchExpenses() {
//
//        let context = CoreDataService.shared.viewContext
//
//        let request = Expense.fetchRequest()
//
//        request.sortDescriptors = [
//            NSSortDescriptor(
//                key: "date",
//                ascending: false
//            )
//        ]
//
//        do {
//
//            expenses = try context.fetch(request)
//
//            print("Fetched \(expenses.count) expenses.")
//
//        } catch {
//
//            print(
//                "Core Data fetch error: \(error.localizedDescription)"
//            )
//        }
//    }
    
    
    func fetchExpenses() {
        guard let userID = FirebaseService.shared.currentUser?.uid else {
            expenses = []
            print("No authenticated user. No expenses fetched.")
            return
        }

        let context = CoreDataService.shared.viewContext
        let request = Expense.fetchRequest()
        
        request.predicate = NSPredicate(
            format: "userID == %@ AND isPendingDeletion == NO",
            userID
        )

        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false)
        ]

        do {
            expenses = try context.fetch(request)
            print("Fetched \(expenses.count) expenses for current user.")
        } catch {
            print("Core Data fetch error: \(error.localizedDescription)")
            expenses = []
        }
    }

    
    func checkCurrentMonthBudgetAlert() {
        let calendar = Calendar.current
        let now = Date()

        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        let context = CoreDataService.shared.viewContext

        guard let userID = FirebaseService.shared.currentUser?.uid else {
            return
        }

        let budgetRequest = Budget.fetchRequest()
        budgetRequest.predicate = NSPredicate(
            format: "userID == %@ AND month == %d AND year == %d",
            userID,
            month,
            year
        )
        budgetRequest.fetchLimit = 1

        let expenseRequest = Expense.fetchRequest()

        guard
            let startOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: now)
            ),
            let startOfNextMonth = calendar.date(
                byAdding: .month,
                value: 1,
                to: startOfMonth
            )
        else {
            return
        }

        expenseRequest.predicate = NSPredicate(
            format: "userID == %@ AND date >= %@ AND date < %@",
            userID,
            startOfMonth as NSDate,
            startOfNextMonth as NSDate
        )

        do {
            guard let budget = try context.fetch(budgetRequest).first else {
                return
            }

            let expenses = try context.fetch(expenseRequest)
            let monthlySpending = expenses.reduce(0.0) {
                $0 + $1.amount
            }

            Task {
                await NotificationService.shared.checkBudgetThresholds(
                    spending: monthlySpending,
                    budget: budget.totalAmount
                )
            }
        } catch {
            print(
                "Budget alert calculation error: \(error.localizedDescription)"
            )
        }
    }

}
 
