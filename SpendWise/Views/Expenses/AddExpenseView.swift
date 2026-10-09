//
//  AddExpenseView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-09.
//

import SwiftUI

struct AddExpenseView: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ExpenseViewModel()

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Header

                VStack(alignment: .leading, spacing: 6) {

                    Text("Add Expense")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.spendWiseText)

                    Text("Record your spending quickly and easily.")
                        .font(.subheadline)
                        .foregroundStyle(Color.spendWiseSecondaryText)
                }

                // MARK: - Amount

                VStack(alignment: .leading, spacing: 10) {

                    Text("Amount")
                        .font(.headline)
                        .foregroundStyle(Color.spendWiseText)

                    HStack {

                        Text("Rs.")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.spendWiseSecondaryText)

                        TextField("0.00", text: $viewModel.amount)
                            .font(.title)
                            .fontWeight(.bold)
                            .keyboardType(.decimalPad)
                    }
                    .padding()
                    .background(Color.spendWiseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.spendWiseBorder,
                                lineWidth: 1
                            )
                    )
                }

                // MARK: - Category

                VStack(alignment: .leading, spacing: 10) {

                    Text("Category")
                        .font(.headline)
                        .foregroundStyle(Color.spendWiseText)

                    Picker("Category", selection: $viewModel.category) {

                        ForEach(
                            viewModel.categories,
                            id: \.self
                        ) { category in

                            Text(category)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.spendWiseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.spendWiseBorder,
                                lineWidth: 1
                            )
                    )
                }

                // MARK: - Merchant

                VStack(alignment: .leading, spacing: 10) {

                    Text("Merchant")
                        .font(.headline)
                        .foregroundStyle(Color.spendWiseText)

                    TextField(
                        "Merchant name (optional)",
                        text: $viewModel.merchant
                    )
                    .padding()
                    .background(Color.spendWiseCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.spendWiseBorder,
                                lineWidth: 1
                            )
                    )
                }

                // MARK: - Error

                if !viewModel.errorMessage.isEmpty {

                    Text(viewModel.errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(Color.spendWiseDanger)
                }

                // MARK: - Save Button

                Button {

                    viewModel.saveExpense()

                } label: {

                    Text("Save Expense")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.spendWiseTeal)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 14)
                        )
                }
            }
            .padding()
        }
        .background(Color.spendWiseBackground)
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Expense Saved",
            isPresented: $viewModel.showSuccessMessage
        ) {

            Button("Done") {

                dismiss()
            }

        } message: {

            Text("Your expense was saved successfully.")
        }
    }
}

#Preview {
    AddExpenseView()
}
