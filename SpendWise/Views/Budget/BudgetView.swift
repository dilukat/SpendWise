//
//  BudgetView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//


import SwiftUI

struct BudgetView: View {

    @StateObject private var viewModel = BudgetViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Current Month
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Budget")
                            .font(.headline)
                            .foregroundColor(Color.spendWiseSecondaryText)

                        Text(Date.now.formatted(.dateTime.month(.wide).year()))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.spendWiseText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Budget Input
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Set Your Budget")
                            .font(.headline)
                            .foregroundColor(Color.spendWiseText)

                        HStack {
                            Text("Rs.")
                                .foregroundColor(Color.spendWiseSecondaryText)

                            TextField("Enter monthly budget", text: $viewModel.totalBudget)
                                .keyboardType(.decimalPad)
                                .foregroundColor(Color.spendWiseText)
                        }
                        .padding()
                        .background(Color.spendWiseBackground)
                        .cornerRadius(12)

                        Button {
                            viewModel.saveMonthlyBudget()
                            viewModel.calculateCurrentMonthSpending()
                        } label: {
                            Text("Save Budget")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.spendWiseTeal)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.spendWiseCard)
                    .cornerRadius(18)

                    
                    // Current Budget Summary
                   VStack(alignment: .leading, spacing: 16) {

                       Text("Budget Summary")
                           .font(.headline)
                           .foregroundColor(Color.spendWiseText)

                       let budgetLimit = viewModel.currentMonthBudget?.totalAmount ?? 0
                       let spent = viewModel.currentMonthSpending
                       let remaining = budgetLimit - spent
                       let progress = budgetLimit > 0
                           ? min(spent / budgetLimit, 1.0)
                           : 0.0

                       HStack {
                           Text("Monthly Limit")
                           Spacer()
                           Text(budgetLimit, format: .currency(code: "LKR"))
                       }

                       HStack {
                           Text("Amount Spent")
                           Spacer()
                           Text(spent, format: .currency(code: "LKR"))
                       }

                       // Budget Progress Bar
                       VStack(alignment: .leading, spacing: 8) {
                           HStack {
                               Text("Budget Used")
                               Spacer()
                               Text("\(Int(budgetLimit > 0 ? (spent / budgetLimit) * 100 : 0))%")
                                   .fontWeight(.semibold)
                           }

                           ProgressView(value: progress)
                               .tint(remaining < 0 ? Color.spendWiseDanger : Color.spendWiseTeal)
                       }

                       HStack {
                           Text(remaining < 0 ? "Amount Over Budget" : "Remaining")
                           Spacer()
                           Text(abs(remaining), format: .currency(code: "LKR"))
                               .foregroundColor(
                                   remaining < 0
                                       ? Color.spendWiseDanger
                                       : Color.spendWiseSuccess
                               )
                       }

                       if budgetLimit <= 0 {
                           Text("Set a monthly budget to track your spending.")
                               .font(.footnote)
                               .foregroundColor(Color.spendWiseSecondaryText)
                       } else if remaining < 0 {
                           Text("You have exceeded your monthly budget.")
                               .font(.footnote)
                               .foregroundColor(Color.spendWiseDanger)
                       } else if progress >= 0.8 {
                           Text("You have used 80% or more of your budget.")
                               .font(.footnote)
                               .foregroundColor(Color.spendWiseWarning)
                       }
                   }
                   .font(.subheadline)
                   .foregroundColor(Color.spendWiseText)
                   .padding()
                   .frame(maxWidth: .infinity, alignment: .leading)
                   .background(Color.spendWiseCard)
                   .cornerRadius(18)

                    // Messages
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(Color.spendWiseDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !viewModel.successMessage.isEmpty {
                        Text(viewModel.successMessage)
                            .foregroundColor(Color.spendWiseSuccess)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .background(Color.spendWiseBackground)
            .navigationTitle("Budget")
            
            .onAppear {
                viewModel.refreshData()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: Notification.Name("ExpenseDidChange")
                )
            ) { _ in
                viewModel.refreshData()
            }

        }
    }
}

#Preview {
    BudgetView()
}

