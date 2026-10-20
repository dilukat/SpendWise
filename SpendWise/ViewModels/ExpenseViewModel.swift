//
//  ExpenseViewModel.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-09.
//

import Foundation
internal import Combine
internal import CoreData

@MainActor
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
    
    init() {
        fetchExpenses()
    }

    func saveExpense() {

        guard let expenseAmount = Double(amount),
              expenseAmount > 0 else {

            errorMessage = "Please enter a valid amount."
            return
        }

        let context = CoreDataService.shared.viewContext

        let expense = Expense(context: context)

        expense.expenseID = UUID().uuidString
        expense.amount = expenseAmount
        expense.category = category
        expense.merchant = merchant
        expense.date = Date()
        expense.latitude = 0
        expense.longitude = 0
        expense.budgetID = ""
        expense.receiptData = receiptData
        expense.latitude = latitude
        expense.longitude = longitude

        CoreDataService.shared.saveContext()

        amount = ""
        merchant = ""
        receiptData = nil
        latitude = 0
        longitude = 0

        errorMessage = ""
        showSuccessMessage = true
        fetchExpenses()

        print("Expense saved successfully.")
    }
    
    
    func deleteExpense(_ expense: Expense) {
        let context = CoreDataService.shared.viewContext

        context.delete(expense)
        CoreDataService.shared.saveContext()

        fetchExpenses()

        print("Expense deleted successfully.")
    }
    
    func fetchExpenses() {

        let context = CoreDataService.shared.viewContext

        let request = Expense.fetchRequest()

        request.sortDescriptors = [
            NSSortDescriptor(
                key: "date",
                ascending: false
            )
        ]

        do {

            expenses = try context.fetch(request)

            print("Fetched \(expenses.count) expenses.")

        } catch {

            print(
                "Core Data fetch error: \(error.localizedDescription)"
            )
        }
    }
}
