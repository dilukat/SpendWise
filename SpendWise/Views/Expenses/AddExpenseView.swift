//
//  AddExpenseView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-09.
//

import SwiftUI

struct AddExpenseView: View {

    @StateObject private var viewModel = ExpenseViewModel()

    var body: some View {

        NavigationStack {

            Form {

                Section("Expense Details") {

                    TextField("Amount", text: $viewModel.amount)
                        .keyboardType(.decimalPad)

                    Picker("Category", selection: $viewModel.category) {

                        ForEach(viewModel.categories, id: \.self) { category in

                            Text(category)
                        }
                    }

                    TextField("Merchant (Optional)", text: $viewModel.merchant)
                }

                Section {

                    Button("Save Expense") {

                        viewModel.saveExpense()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.spendWiseTeal)
                }

                if !viewModel.errorMessage.isEmpty {

                    Section {

                        Text(viewModel.errorMessage)
                            .foregroundStyle(Color.spendWiseDanger)
                    }
                }
            }
            .navigationTitle("Add Expense")
            .alert(
                "Expense Saved",
                isPresented: $viewModel.showSuccessMessage
            ) {

                Button("OK") { }

            } message: {

                Text("Your expense was saved successfully.")
            }
        }
    }
}

#Preview {
    AddExpenseView()
}
