//
//  BudgetViewModel.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-16.
//

import Foundation
import CoreData
internal import Combine
import FirebaseAuth

@MainActor
final class BudgetViewModel: ObservableObject {

    @Published var totalBudget = ""
    @Published var errorMessage = ""
    @Published var successMessage = ""
    @Published var budgets: [Budget] = []
    
    @Published var currentMonthBudget: Budget?
    @Published var currentMonthSpending: Double = 0

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

    init() {
        refreshData()
    }
    
    
    // Fetch Category Budgets
    func fetchCategoryBudgets() {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid,
              let currentBudget = currentMonthBudget,
              let budgetID = currentBudget.budgetID,
              currentBudget.userID == userID else {
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
            categoryBudgets = []
        }
    }


   // Calculate Category Spending
    func calculateCategorySpending() {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            categorySpending = [:]
            print("No authenticated user. Category calculation skipped.")
            return
        }

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
            format: "userID == %@ AND date >= %@ AND date < %@",
            userID,
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


   // Save Category Budget
    func saveCategoryBudget() {
        if let validationError = BudgetValidator.validateCategoryBudget(categoryLimit) {
            errorMessage = validationError
            successMessage = ""
            return
        }

        let amount = Double(
            categoryLimit.trimmingCharacters(in: .whitespacesAndNewlines)
        )!

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

            let categoryBudgetToSync = categoryBudget
            let monthlyBudgetToSync = monthlyBudget
            let categoryName = selectedCategory

            categoryLimit = ""
            errorMessage = ""
            successMessage = "\(categoryName) budget saved locally."

            fetchCategoryBudgets()

            Task { @MainActor in
                do {
                    try await FirestoreSyncService.shared.uploadCategoryBudget(
                        categoryBudgetToSync,
                        monthlyBudget: monthlyBudgetToSync
                    )

                    successMessage = "\(categoryName) budget saved and synced successfully."
                    print("Category budget synced to Firestore: \(categoryName)")
                } catch {
                    successMessage = "\(categoryName) budget saved locally, but cloud sync failed."
                    print("Category budget sync failed: \(error.localizedDescription)")
                }
            }

        } catch {
            errorMessage = "Unable to save the category budget."
            successMessage = ""
            print("Category budget save error: \(error.localizedDescription)")
        }
    }


   // Category Budget Lookup
   func budgetLimit(for category: String) -> Double {
       categoryBudgets.first {
           $0.category == category
       }?.limit ?? 0
   }

   func spending(for category: String) -> Double {
       categorySpending[category] ?? 0
   }


    // Fetch Budgets
    func fetchBudgets() {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            budgets = []
            currentMonthBudget = nil
            print("No authenticated user. No budgets fetched.")
            return
        }

        let context = CoreDataService.shared.viewContext
        let request = Budget.fetchRequest()

        request.predicate = NSPredicate(
            format: "userID == %@",
            userID
        )

        request.sortDescriptors = [
            NSSortDescriptor(key: "year", ascending: false),
            NSSortDescriptor(key: "month", ascending: false)
        ]

        do {
            budgets = try context.fetch(request)
            updateCurrentMonthBudget()
            print("Fetched \(budgets.count) budgets for current user.")
        } catch {
            print("Budget fetch error: \(error.localizedDescription)")
            budgets = []
            currentMonthBudget = nil
        }
    }

    // Current Month Budget
    func updateCurrentMonthBudget() {
        let calendar = Calendar.current
        let now = Date()

        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        currentMonthBudget = budgets.first {
            Int($0.month) == month && Int($0.year) == year
        }
    }

    // Save Monthly Budget
    func saveMonthlyBudget() {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            errorMessage = "Please log in to save a budget."
            successMessage = ""
            return
        }

//        let trimmedAmount = totalBudget.trimmingCharacters(
//            in: .whitespacesAndNewlines
//        )
//
//        guard let amount = Double(trimmedAmount),
//              amount.isFinite,
//              amount > 0 else {
//            errorMessage = "Please enter a valid budget amount greater than zero."
//            successMessage = ""
//            return
//        }
        
        if let validationError = BudgetValidator.validateMonthlyBudget(totalBudget) {
            errorMessage = validationError
            successMessage = ""
            return
        }

        let amount = Double(
            totalBudget.trimmingCharacters(in: .whitespacesAndNewlines)
        )!

        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        let context = CoreDataService.shared.viewContext

        let existingBudget = budgets.first {
            $0.userID == userID &&
            Int($0.month) == month &&
            Int($0.year) == year
        }

        let budgetToSync: Budget

        if let existingBudget {
            guard let budgetID = existingBudget.budgetID,
                  !budgetID.isEmpty else {
                errorMessage = "The monthly budget ID is missing."
                successMessage = ""
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
                let categoryBudgets = try context.fetch(request)
                let allocatedTotal = categoryBudgets.reduce(0.0) {
                    $0 + $1.limit
                }

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
            budgetToSync = existingBudget

        } else {
            let budget = Budget(context: context)
            budget.budgetID = UUID().uuidString
            budget.userID = userID
            budget.month = Int16(month)
            budget.year = Int16(year)
            budget.totalAmount = amount
            budget.createdDate = Date()

            budgetToSync = budget
        }

        CoreDataService.shared.saveContext()

        errorMessage = ""
        successMessage = "Monthly budget saved locally."
        totalBudget = ""

        fetchBudgets()

        Task { @MainActor in
            do {
                try await FirestoreSyncService.shared.uploadBudget(budgetToSync)
                successMessage = "Monthly budget saved and synced successfully."
                print("Budget synced to Firestore.")
            } catch {
                successMessage = "Monthly budget saved locally, but cloud sync failed."
                print("Budget cloud sync failed: \(error.localizedDescription)")
            }
        }
    }

    
    // Refresh Budget Data
   func refreshData() {
       fetchBudgets()
       calculateCurrentMonthSpending()
       fetchCategoryBudgets()
       calculateCategorySpending()
   }


    // Calculate Current Month Spending
    func calculateCurrentMonthSpending() {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            currentMonthSpending = 0
            print("No authenticated user. Spending calculation skipped.")
            return
        }

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
            format: "userID == %@ AND date >= %@ AND date < %@",
            userID,
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
