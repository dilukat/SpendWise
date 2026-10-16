//
//  BudgetView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//


import SwiftUI

struct BudgetView: View {

    @State private var snackbarMessage = ""
    @State private var showingSnackbar = false
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
                       let progress = viewModel.progressValue(
                           spending: spent,
                           limit: budgetLimit
                       )

                       let percentage = viewModel.percentageUsed(
                           spending: spent,
                           limit: budgetLimit
                       )

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
                               Text("\(percentage)%")
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
                    
                    
                    //MARK: Validation Error Banner
                   if !viewModel.errorMessage.isEmpty {
                       HStack(alignment: .top, spacing: 10) {
                           Image(systemName: "exclamationmark.circle.fill")
                               .foregroundColor(Color.spendWiseDanger)

                           Text(viewModel.errorMessage)
                               .font(.subheadline)
                               .foregroundColor(Color.spendWiseText)
                               .frame(maxWidth: .infinity, alignment: .leading)

                           Button {
                               viewModel.errorMessage = ""
                           } label: {
                               Image(systemName: "xmark")
                                   .foregroundColor(Color.spendWiseSecondaryText)
                           }
                           .buttonStyle(.plain)
                       }
                       .padding()
                       .frame(maxWidth: .infinity, alignment: .leading)
                       .background(Color.spendWiseDanger.opacity(0.10))
                       .clipShape(RoundedRectangle(cornerRadius: 12))
                   }

                    
                    // MARK: - Category Budgets

                   VStack(alignment: .leading, spacing: 16) {

                       Text("Category Budgets")
                           .font(.headline)
                           .foregroundColor(Color.spendWiseText)

                       Text("Set a separate monthly limit for each category.")
                           .font(.subheadline)
                           .foregroundColor(Color.spendWiseSecondaryText)

                       Picker("Category", selection: $viewModel.selectedCategory) {
                           ForEach(viewModel.categories, id: \.self) { category in
                               Text(category).tag(category)
                           }
                       }
                       .pickerStyle(.menu)
                       .tint(Color.spendWiseTeal)

                       HStack {
                           Text("Rs.")
                               .foregroundColor(Color.spendWiseSecondaryText)

                           TextField("Enter category limit", text: $viewModel.categoryLimit)
                               .keyboardType(.decimalPad)
                               .foregroundColor(Color.spendWiseText)
                       }
                       .padding()
                       .background(Color.spendWiseBackground)
                       .cornerRadius(12)

                       Button {
                           viewModel.saveCategoryBudget()
                       } label: {
                           Text("Save Category Budget")
                               .fontWeight(.semibold)
                               .frame(maxWidth: .infinity)
                               .padding()
                               .background(Color.spendWiseTeal)
                               .foregroundColor(.white)
                               .cornerRadius(12)
                       }

                       Divider()

                       ForEach(viewModel.categories, id: \.self) { category in

                           let limit = viewModel.budgetLimit(for: category)
                           let spent = viewModel.spending(for: category)

                           let progress = viewModel.progressValue(
                               spending: spent,
                               limit: limit
                           )

                           let percentage = viewModel.percentageUsed(
                               spending: spent,
                               limit: limit
                           )

                           VStack(alignment: .leading, spacing: 8) {

                               HStack {
                                   Text(category)
                                       .fontWeight(.medium)

                                   Spacer()

                                   Text(spent, format: .currency(code: "LKR"))
                                       .fontWeight(.semibold)
                               }

                               if limit > 0 {
                                   ProgressView(value: progress)
                                       .tint(spent > limit
                                             ? Color.spendWiseDanger
                                             : Color.spendWiseTeal)

                                   HStack {
                                       Text("Limit: \(limit, format: .currency(code: "LKR"))")
                                       Spacer()

                                       Text(
                                           spent > limit
                                           ? "Over budget • \(percentage)% used"
                                           : "\(percentage)% used"
                                       )
                                       .foregroundColor(
                                           spent > limit
                                           ? Color.spendWiseDanger
                                           : Color.spendWiseSecondaryText
                                       )
                                   }
                                   .font(.caption)
                               } else {
                                   Text("No limit set")
                                       .font(.caption)
                                       .foregroundColor(Color.spendWiseSecondaryText)
                               }
                           }
                           .foregroundColor(Color.spendWiseText)

                           if category != viewModel.categories.last {
                               Divider()
                           }
                       }
                   }
                   .padding()
                   .frame(maxWidth: .infinity, alignment: .leading)
                   .background(Color.spendWiseCard)
                   .cornerRadius(18)

                    
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
            
            .onChange(of: viewModel.successMessage) { _, newValue in
                guard !newValue.isEmpty else { return }

                snackbarMessage = newValue
                showingSnackbar = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if snackbarMessage == newValue {
                        withAnimation {
                            showingSnackbar = false
                        }

                        snackbarMessage = ""
                        viewModel.successMessage = ""
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showingSnackbar {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.spendWiseSuccess)

                        Text(snackbarMessage)
                            .font(.subheadline)
                            .foregroundColor(Color.spendWiseText)

                        Spacer()
                    }
                    .padding()
                    .background(Color.spendWiseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showingSnackbar)



        }
    }
}

#Preview {
    BudgetView()
}

