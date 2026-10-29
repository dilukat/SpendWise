//
//  HomeView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//


import SwiftUI
import CoreData
import FirebaseAuth

private struct CategoryBudgetSummary: Identifiable {
    let category: String
    let limit: Double
    let spent: Double

    var id: String { category }
}

struct HomeView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState

    @State private var totalSpending: Double = 0
    @State private var monthlyBudget: Double = 0
    @State private var errorMessage = ""
    @State private var recentExpenses: [Expense] = []
    @State private var categoryBudgetSummaries: [CategoryBudgetSummary] = []
    @State private var categorySpending: [String: Double] = [:]
    @State private var predictedMonthlySpending: Double?
    @State private var isRefreshingFromCloud = false

    private var remainingBudget: Double {
        monthlyBudget - totalSpending
    }

    private var percentageUsed: Int {
        guard monthlyBudget > 0 else { return 0 }
        return Int((totalSpending / monthlyBudget * 100).rounded())
    }

    private var progress: Double {
        guard monthlyBudget > 0 else { return 0 }
        return min(max(totalSpending / monthlyBudget, 0), 1)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Welcome Header
//                    VStack(alignment: .leading, spacing: 6) {
//                        Text("Welcome to SpendWise")
//                            .font(.title)
//                            .fontWeight(.bold)
//                            .foregroundColor(Color.spendWiseText)
//                            .padding(.top , 10)
//
//                        Text(Date.now.formatted(
//                            .dateTime.month(.wide).year()
//                        ))
//                        .foregroundColor(Color.spendWiseSecondaryText)
//                        .padding(.top , 5)
//                    }

                    // Monthly Spending Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Total Monthly Spending")
                            .font(.headline)
                            .foregroundColor(Color.spendWiseSecondaryText)

                        Text(
                            totalSpending,
                            format: .currency(code: "LKR")
                        )
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.spendWiseText)

                        Divider()

                        HStack {
                            Text("Monthly Budget")
                            Spacer()
                            Text(
                                monthlyBudget,
                                format: .currency(code: "LKR")
                            )
                            .fontWeight(.semibold)
                        }

                        HStack {
                            Text(
                                remainingBudget < 0
                                ? "Amount Over Budget"
                                : "Remaining Budget"
                            )

                            Spacer()

                            Text(
                                abs(remainingBudget),
                                format: .currency(code: "LKR")
                            )
                            .fontWeight(.semibold)
                            .foregroundColor(
                                remainingBudget < 0
                                ? Color.spendWiseDanger
                                : Color.spendWiseSuccess
                            )
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.spendWiseText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.spendWiseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    // Add Expense Shortcut
                    NavigationLink {
                        AddExpenseView()
                    } label: {
                        Label("Add Expense", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.spendWiseTeal)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(Color.spendWiseDanger)
                    }

                    // Monthly Budget Progress
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Monthly Budget Progress")
                                .font(.headline)

                            Spacer()

                            Text("\(percentageUsed)%")
                                .fontWeight(.semibold)
                        }

                        ProgressView(value: progress)
                            .tint(
                                totalSpending > monthlyBudget
                                ? Color.spendWiseDanger
                                : progress >= 0.8
                                    ? Color.spendWiseWarning
                                    : Color.spendWiseTeal
                            )

                        
                        if monthlyBudget <= 0 {
                            Label(
                                "Set a monthly budget to track your spending.",
                                systemImage: "info.circle"
                            )
                            .font(.footnote)
                            .foregroundColor(Color.spendWiseSecondaryText)

                        } else if totalSpending > monthlyBudget {
                            Label(
                                "You've exceeded your monthly budget.",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .font(.footnote)
                            .foregroundColor(Color.spendWiseDanger)

                        } else if totalSpending == monthlyBudget {
                            Label(
                                "You've reached your monthly budget.",
                                systemImage: "exclamationmark.circle.fill"
                            )
                            .font(.footnote)
                            .foregroundColor(Color.spendWiseWarning)

                        } else if progress >= 0.8 {
                            Label(
                                "You've used 80% or more of your budget.",
                                systemImage: "exclamationmark.circle.fill"
                            )
                            .font(.footnote)
                            .foregroundColor(Color.spendWiseWarning)

                        } else {
                            Label(
                                "You're within your monthly budget.",
                                systemImage: "checkmark.circle.fill"
                            )
                            .font(.footnote)
                            .foregroundColor(Color.spendWiseSuccess)
                        }

                    }
                    .foregroundColor(Color.spendWiseText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.spendWiseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    //Spending Prediction

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.spendWiseTeal)

                            Text("Spending Prediction")
                                .font(.headline)
                                .foregroundColor(.spendWiseText)
                        }

                        if let predicted = predictedMonthlySpending {
                            Text(
                                predicted,
                                format: .currency(
                                    code: Locale.current.currency?.identifier ?? "LKR"
                                )
                            )
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.spendWiseText)

                            Text("Estimated total spending by the end of this month")
                                .font(.subheadline)
                                .foregroundColor(.spendWiseSecondaryText)

                            if monthlyBudget > 0 {
                                let difference = predicted - monthlyBudget

                                if difference > 0 {
                                    Label(
                                        "Predicted to exceed budget by " +
                                        difference.formatted(
                                            .currency(
                                                code: Locale.current.currency?.identifier ?? "LKR"
                                            )
                                        ),
                                        systemImage: "exclamationmark.triangle.fill"
                                    )
                                    .foregroundColor(.spendWiseDanger)
                                    .font(.subheadline)
                                } else {
                                    Label(
                                        "Predicted to stay within budget",
                                        systemImage: "checkmark.circle.fill"
                                    )
                                    .foregroundColor(.spendWiseSuccess)
                                    .font(.subheadline)
                                }
                            }
                        } else {
                            Text("Prediction is currently unavailable.")
                                .font(.subheadline)
                                .foregroundColor(.spendWiseSecondaryText)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.spendWiseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    
                    
                    // Category Budget Overview

                   VStack(alignment: .leading, spacing: 16) {

                       Text("Category Budget Overview")
                           .font(.headline)
                           .foregroundColor(Color.spendWiseText)

                       if categoryBudgetSummaries.isEmpty {

                           Text("No category budgets set for this month.")
                               .font(.subheadline)
                               .foregroundColor(Color.spendWiseSecondaryText)
                               .padding(.vertical, 8)

                       } else {

                           ForEach(categoryBudgetSummaries) { item in

                               let percentage = item.limit > 0
                                   ? Int((item.spent / item.limit * 100).rounded())
                                   : 0

                               let progress = item.limit > 0
                                   ? min(max(item.spent / item.limit, 0), 1)
                                   : 0

                               VStack(alignment: .leading, spacing: 8) {

                                   HStack {
                                       Text(item.category)
                                           .font(.subheadline)
                                           .fontWeight(.semibold)

                                       Spacer()

                                       Text(
                                           item.spent > item.limit
                                               ? "Over budget • \(percentage)%"
                                               : "\(percentage)% used"
                                       )
                                       .font(.caption)
                                       .fontWeight(.medium)
                                       .foregroundColor(
                                           item.spent > item.limit
                                               ? Color.spendWiseDanger
                                               : progress >= 0.8
                                                   ? Color.spendWiseWarning
                                                   : Color.spendWiseSecondaryText
                                       )
                                   }

                                   ProgressView(value: progress)
                                       .tint(
                                           item.spent > item.limit
                                               ? Color.spendWiseDanger
                                               : progress >= 0.8
                                                   ? Color.spendWiseWarning
                                                   : Color.spendWiseTeal
                                       )

                                   HStack {
                                       Text(
                                           "Spent: \(item.spent, format: .currency(code: "LKR"))"
                                       )

                                       Spacer()

                                       Text(
                                           "Limit: \(item.limit, format: .currency(code: "LKR"))"
                                       )
                                   }
                                   .font(.caption2)
                                   .foregroundColor(Color.spendWiseSecondaryText)
                               }

                               if item.id != categoryBudgetSummaries.last?.id {
                                   Divider()
                               }
                           }
                       }
                   }
                   .padding()
                   .frame(maxWidth: .infinity, alignment: .leading)
                   .background(Color.spendWiseCard)
                   .clipShape(RoundedRectangle(cornerRadius: 18))


                    
                    
                    // Recent Expenses

                   VStack(alignment: .leading, spacing: 16) {

                       HStack {
                           Text("Recent Expenses")
                               .font(.headline)
                               .foregroundColor(Color.spendWiseText)

                           Spacer()

                           Text("\(recentExpenses.count) items")
                               .font(.caption)
                               .foregroundColor(Color.spendWiseSecondaryText)
                       }

                       if recentExpenses.isEmpty {

                           VStack(spacing: 10) {
                               Image(systemName: "receipt")
                                   .font(.largeTitle)
                                   .foregroundColor(Color.spendWiseSecondaryText)

                               Text("No expenses yet")
                                   .font(.headline)
                                   .foregroundColor(Color.spendWiseText)

                               Text("Your recent expenses will appear here.")
                                   .font(.subheadline)
                                   .foregroundColor(Color.spendWiseSecondaryText)
                                   .multilineTextAlignment(.center)
                           }
                           .frame(maxWidth: .infinity)
                           .padding(.vertical, 24)

                       } else {

                           ForEach(recentExpenses, id: \.objectID) { expense in

                               HStack(spacing: 12) {

                                   Image(systemName: "receipt")
                                       .font(.title3)
                                       .foregroundColor(Color.spendWiseTeal)
                                       .frame(width: 44, height: 44)
                                       .background(Color.spendWiseBackground)
                                       .clipShape(RoundedRectangle(cornerRadius: 12))

                                   VStack(alignment: .leading, spacing: 5) {

                                       Text(expense.category ?? "Other")
                                           .font(.subheadline)
                                           .fontWeight(.semibold)
                                           .foregroundColor(Color.spendWiseText)

                                       Text(expense.merchant ?? "Unknown merchant")
                                           .font(.caption)
                                           .foregroundColor(Color.spendWiseSecondaryText)
                                           .lineLimit(1)

                                       Text(
                                           (expense.date ?? Date()).formatted(
                                               .dateTime.day().month(.abbreviated).year()
                                           )
                                       )
                                       .font(.caption2)
                                       .foregroundColor(Color.spendWiseSecondaryText)
                                   }

                                   Spacer(minLength: 8)

                                   Text(
                                       expense.amount,
                                       format: .currency(code: "LKR")
                                   )
                                   .font(.subheadline)
                                   .fontWeight(.semibold)
                                   .foregroundColor(Color.spendWiseText)
                                   .lineLimit(1)
                                   .minimumScaleFactor(0.8)
                               }

                               if expense.objectID != recentExpenses.last?.objectID {
                                   Divider()
                               }
                           }
                       }
                   }
                   .padding()
                   .frame(maxWidth: .infinity, alignment: .leading)
                   .background(Color.spendWiseCard)
                   .clipShape(RoundedRectangle(cornerRadius: 18))

                    
                    
                }
                .padding()
            }
            .background(Color.spendWiseBackground)
            //.navigationTitle("Home")
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Text("Welcome to SpendWise")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.spendWiseText)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 15)
                .padding(.bottom, 12)
                .background(Color.spendWiseBackground)
            }
            .onAppear {
                Task {
                    await syncAndRefreshDashboard()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await syncAndRefreshDashboard()
                    }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: Notification.Name("ExpenseDidChange")
                )
            ) { _ in
                refreshDashboard()
            }
            .onChange(of: appState.currentUserID) { _, newUserID in
                if newUserID != nil {
                    Task {
                        await syncAndRefreshDashboard()
                    }
                }else {
                    totalSpending = 0
                    monthlyBudget = 0
                    recentExpenses = []
                    categoryBudgetSummaries = []
                    categorySpending = [:]
                    predictedMonthlySpending = nil
                    errorMessage = ""
                }
            }
        }
    }

    
    @MainActor
    private func syncAndRefreshDashboard() async {
        guard Auth.auth().currentUser?.uid != nil else {
            refreshDashboard()
            return
        }

        guard !isRefreshingFromCloud else {
            return
        }

        isRefreshingFromCloud = true
        defer {
            isRefreshingFromCloud = false
        }

        do {
            _ = try await FirestoreSyncService.shared.downloadBudgets()

            _ = try await FirestoreSyncService.shared.downloadCategoryBudgets()

            _ = try await FirestoreSyncService.shared.downloadExpenses()

        } catch {
            errorMessage = "Unable to sync dashboard data."
            print("Dashboard cloud sync error: \(error.localizedDescription)")
        }
        refreshDashboard()
    }

    
    // Refresh Dashboard

    private func refreshDashboard() {
        let context = CoreDataService.shared.viewContext
        let calendar = Calendar.current
        let now = Date()

        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

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

        // Fetch this month's expenses
        
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            totalSpending = 0
            categorySpending = [:]
            recentExpenses = []
            monthlyBudget = 0
            predictedMonthlySpending = nil
            categoryBudgetSummaries = []
            errorMessage = ""
            return
        }

        // Fetch this user's expenses for the current month.
        let expenseRequest = Expense.fetchRequest()

        expenseRequest.predicate = NSPredicate(
            format: "userID == %@ AND date >= %@ AND date < %@",
            userID,
            startOfMonth as NSDate,
            startOfNextMonth as NSDate
        )


        do {
            let expenses = try context.fetch(expenseRequest)

            totalSpending = expenses.reduce(0) {
                $0 + $1.amount
            }
            
            var totals: [String: Double] = [:]

            for expense in expenses {
                let category = expense.category ?? "Other"
                totals[category, default: 0] += expense.amount
            }

            categorySpending = totals

            errorMessage = ""
        } catch {
            errorMessage = "Unable to load monthly spending."
            print("Dashboard expense fetch error: \(error.localizedDescription)")
        }
       
        // Fetch the five most recent expenses for this user.
       let recentRequest = Expense.fetchRequest()

       recentRequest.predicate = NSPredicate(
           format: "userID == %@",
           userID
       )

       recentRequest.sortDescriptors = [
           NSSortDescriptor(key: "date", ascending: false)
       ]

       recentRequest.fetchLimit = 5


       do {
           recentExpenses = try context.fetch(recentRequest)
       } catch {
           errorMessage = "Unable to load recent expenses."
           print("Recent expense fetch error: \(error.localizedDescription)")
       }
        
        // Fetch this user's budget for the current month.
       let budgetRequest = Budget.fetchRequest()

       budgetRequest.predicate = NSPredicate(
           format: "userID == %@ AND month == %d AND year == %d",
           userID,
           month,
           year
       )

        do {
            
            let budgets = try context.fetch(budgetRequest)
            let currentBudget = budgets.first

            monthlyBudget = currentBudget?.totalAmount ?? 0

            // Refresh the prediction even if no monthly budget exists.
            predictedMonthlySpending =
                SpendingPredictionService.shared.predictMonthlySpending()

            guard let budgetID = currentBudget?.budgetID,
                  !budgetID.isEmpty else {
                categoryBudgetSummaries = []
                return
            }

            // Fetch category allocations for this monthly budget
            let categoryRequest = NSFetchRequest<CategoryBudget>(
                entityName: "CategoryBudget"
            )

            categoryRequest.predicate = NSPredicate(
                format: "budgetID == %@",
                budgetID
            )

            do {
                let categoryBudgets = try context.fetch(categoryRequest)

                categoryBudgetSummaries = categoryBudgets.map { item in
                    let category = item.category ?? "Other"

                    return CategoryBudgetSummary(
                        category: category,
                        limit: item.limit,
                        spent: categorySpending[category] ?? 0
                    )
                }
                .sorted { $0.category < $1.category }

            } catch {
                categoryBudgetSummaries = []
                errorMessage = "Unable to load category budgets."
                print("Category budget fetch error: \(error.localizedDescription)")
            }

        } catch {
            errorMessage = "Unable to load the monthly budget."
            print("Dashboard budget fetch error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    HomeView()
}
