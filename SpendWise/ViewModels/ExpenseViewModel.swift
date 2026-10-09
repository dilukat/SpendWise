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

    @Published var errorMessage = ""
    @Published var showSuccessMessage = false

    let categories = [
        "Food",
        "Transport",
        "Shopping",
        "Bills",
        "Entertainment",
        "Health",
        "Other"
    ]

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

        CoreDataService.shared.saveContext()

        amount = ""
        merchant = ""

        errorMessage = ""
        showSuccessMessage = true

        print("Expense saved successfully.")
    }
}
