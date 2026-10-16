//
//  BudgetViewModel.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-16.
//

import Foundation
import CoreData
internal import Combine

@MainActor
final class BudgetViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var totalBudget = ""
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var budgets: [Budget] = []
    
    @Published var currentMonthBudget: Budget?
    @Published var currentMonthSpending: Double = 0

    // MARK: - Initialization

    init() {
        fetchBudgets()
        calculateCurrentMonthSpending()
    }

    // MARK: - Fetch Budgets

    func fetchBudgets() {
        let context = CoreDataService.shared.viewContext
        let request = Budget.fetchRequest()

        request.sortDescriptors = [
            NSSortDescriptor(key: "year", ascending: false),
            NSSortDescriptor(key: "month", ascending: false)
        ]

        do {
            budgets = try context.fetch(request)
            updateCurrentMonthBudget()
        } catch {
            errorMessage = "Unable to load budgets: \(error.localizedDescription)"
            print("Budget fetch error: \(error.localizedDescription)")
        }
    }

    // MARK: - Current Month Budget

    func updateCurrentMonthBudget() {
        let calendar = Calendar.current
        let now = Date()

        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        currentMonthBudget = budgets.first {
            Int($0.month) == month && Int($0.year) == year
        }
    }

    // MARK: - Save Monthly Budget

    func saveMonthlyBudget() {
        let trimmedAmount = totalBudget.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let amount = Double(trimmedAmount),
              amount.isFinite,
              amount > 0 else {
            errorMessage = "Please enter a valid budget amount greater than zero."
            successMessage = ""
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        let context = CoreDataService.shared.viewContext

        let existingBudget = budgets.first {
            Int($0.month) == month && Int($0.year) == year
        }

        if let existingBudget {
            // Update the existing budget for this month.
            existingBudget.totalAmount = amount
        } else {
            // Create a new budget for this month.
            let budget = Budget(context: context)
            budget.budgetID = UUID().uuidString
            budget.userID = ""
            budget.month = Int16(month)
            budget.year = Int16(year)
            budget.totalAmount = amount
            budget.createdDate = Date()
        }

        CoreDataService.shared.saveContext()

        errorMessage = ""
        successMessage = "Monthly Budget Set!"
        totalBudget = ""

        fetchBudgets()
    }
    
    
    // MARK: - Refresh Budget Data

   func refreshData() {
       fetchBudgets()
       calculateCurrentMonthSpending()
   }


    // MARK: - Calculate Current Month Spending

    func calculateCurrentMonthSpending() {
        let calendar = Calendar.current
        let now = Date()

        guard let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ),
        let startOfNextMonth = calendar.date(
            byAdding: .month,
            value: 1,
            to: startOfMonth
        ) else {
            return
        }

        let request = Expense.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfMonth as NSDate,
            startOfNextMonth as NSDate
        )

        do {
            let expenses = try CoreDataService.shared.viewContext.fetch(request)
            currentMonthSpending = expenses.reduce(0) {
                $0 + $1.amount
            }
        } catch {
            errorMessage = "Unable to calculate spending."
            print("Monthly spending error: \(error.localizedDescription)")
        }
    }
}
