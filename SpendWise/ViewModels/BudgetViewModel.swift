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
    
    
    // MARK: - Category Budget Properties

    let categories = [
        "Food",
        "Transport",
        "Shopping",
        "Bills",
        "Entertainment",
        "Health",
        "Other"
    ]

    @Published var selectedCategory = "Food"
    @Published var categoryLimit = ""

    @Published var categoryBudgets: [CategoryBudget] = []
    @Published var categorySpending: [String: Double] = [:]

    // MARK: - Initialization

    init() {
        refreshData()
    }
    
    
    // MARK: - Fetch Category Budgets

   func fetchCategoryBudgets() {
       guard let budgetID = currentMonthBudget?.budgetID else {
           categoryBudgets = []
           return
       }

       let request = NSFetchRequest<CategoryBudget>(
           entityName: "CategoryBudget"
       )

       request.predicate = NSPredicate(
           format: "budgetID == %@",
           budgetID
       )

       do {
           categoryBudgets = try CoreDataService.shared
               .viewContext.fetch(request)
       } catch {
           errorMessage = "Unable to load category budgets."
           print("Category budget fetch error: \(error.localizedDescription)")
       }
   }

   // MARK: - Calculate Category Spending

   func calculateCategorySpending() {
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

       let request = NSFetchRequest<Expense>(entityName: "Expense")

       request.predicate = NSPredicate(
           format: "date >= %@ AND date < %@",
           startOfMonth as NSDate,
           startOfNextMonth as NSDate
       )

       do {
           let expenses = try CoreDataService.shared
               .viewContext.fetch(request)

           var totals: [String: Double] = [:]

           for category in categories {
               totals[category] = expenses
                   .filter { $0.category == category }
                   .reduce(0) { $0 + $1.amount }
           }

           categorySpending = totals

       } catch {
           errorMessage = "Unable to calculate category spending."
           print("Category spending error: \(error.localizedDescription)")
       }
   }

   // MARK: - Save Category Budget

   
    func saveCategoryBudget() {
        let trimmedAmount = categoryLimit.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let amount = Double(trimmedAmount),
              amount.isFinite,
              amount > 0 else {
            errorMessage = "Enter a valid category limit greater than zero."
            successMessage = ""
            return
        }

        guard let monthlyBudget = currentMonthBudget else {
            errorMessage = "Please save your monthly budget first."
            successMessage = ""
            return
        }

        guard let budgetID = monthlyBudget.budgetID,
              !budgetID.isEmpty else {
            errorMessage = "Monthly budget ID is missing. Please save your monthly budget again."
            successMessage = ""
            return
        }
        let context = CoreDataService.shared.viewContext

        let request = NSFetchRequest<CategoryBudget>(
            entityName: "CategoryBudget"
        )

        request.predicate = NSPredicate(
            format: "budgetID == %@",
            budgetID
        )

        do {
            let existingBudgets = try context.fetch(request)

            // Exclude the selected category's old limit when editing it.
            let otherCategoryLimits = existingBudgets
                .filter { $0.category != selectedCategory }
                .reduce(0.0) { $0 + $1.limit }

            let proposedTotal = otherCategoryLimits + amount

            // Prevent category limits from exceeding the monthly budget.
            guard proposedTotal <= monthlyBudget.totalAmount else {
                let available = max(
                    0,
                    monthlyBudget.totalAmount - otherCategoryLimits
                )

                errorMessage = """
                This limit exceeds your monthly budget.
                Maximum available for \(selectedCategory): \
                \(available.formatted(.currency(code: "LKR")))
                """

                successMessage = ""
                return
            }

            let categoryBudget: CategoryBudget

            if let existing = existingBudgets.first(where: {
                $0.category == selectedCategory
            }) {
                categoryBudget = existing
            } else {
                categoryBudget = CategoryBudget(context: context)
                categoryBudget.budgetID = budgetID
                categoryBudget.category = selectedCategory
                categoryBudget.month = monthlyBudget.month
            }

            categoryBudget.limit = amount

            CoreDataService.shared.saveContext()

            categoryLimit = ""
            errorMessage = ""
            successMessage = "\(selectedCategory) budget saved successfully."

            fetchCategoryBudgets()

        } catch {
            errorMessage = "Unable to save the category budget."
            successMessage = ""
            print("Category budget save error: \(error.localizedDescription)")
        }
    }


   // MARK: - Category Budget Lookup

   func budgetLimit(for category: String) -> Double {
       categoryBudgets.first {
           $0.category == category
       }?.limit ?? 0
   }

   func spending(for category: String) -> Double {
       categorySpending[category] ?? 0
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
            guard let budgetID = existingBudget.budgetID,
                  !budgetID.isEmpty else {
                errorMessage = "The monthly budget ID is missing."
                successMessage = ""
                return
            }

            // Fetch category allocations for this monthly budget.
            let request = NSFetchRequest<CategoryBudget>(
                entityName: "CategoryBudget"
            )

            request.predicate = NSPredicate(
                format: "budgetID == %@",
                budgetID
            )

            do {
                let categoryBudgets = try context.fetch(request)

                let allocatedTotal = categoryBudgets.reduce(0.0) {
                    $0 + $1.limit
                }

                // The monthly budget cannot be lower than allocations.
                guard amount >= allocatedTotal else {
                    errorMessage = """
                    Your monthly budget cannot be lower than your total
                    category allocations of \
                    \(allocatedTotal.formatted(.currency(code: "LKR"))).
                    Increase the monthly budget or reduce category limits first.
                    """
                    successMessage = ""
                    return
                }

            } catch {
                errorMessage = "Unable to validate your category allocations."
                successMessage = ""
                print("Category allocation error: \(error.localizedDescription)")
                return
            }

            existingBudget.totalAmount = amount

        } else {
            // Create a new monthly budget.
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
        successMessage = "Monthly budget saved successfully."
        totalBudget = ""

        fetchBudgets()
    }

    
    
    // MARK: - Refresh Budget Data

   func refreshData() {
       fetchBudgets()
       calculateCurrentMonthSpending()
       fetchCategoryBudgets()
       calculateCategorySpending()
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

            // Check whether the monthly budget threshold has been reached.
            if let budget = currentMonthBudget {
                let spending = currentMonthSpending
                let budgetAmount = budget.totalAmount

                Task {
                    await NotificationService.shared.checkBudgetThresholds(
                        spending: spending,
                        budget: budgetAmount
                    )
                }
            }
        } catch {
            errorMessage = "Unable to calculate spending."
            print("Monthly spending error: \(error.localizedDescription)")
        }
    }
    
    func percentageUsed(spending: Double, limit: Double) -> Int {
        guard limit > 0 else {
            return 0
        }

        return Int((spending / limit * 100).rounded())
    }

    func progressValue(spending: Double, limit: Double) -> Double {
        guard limit > 0 else {
            return 0
        }

        return min(max(spending / limit, 0), 1)
    }
    
}
