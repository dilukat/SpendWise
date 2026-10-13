//
//  EditExpenseView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-13.
//


import SwiftUI

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss

    let expense: Expense

    @State private var amount: String
    @State private var category: String
    @State private var merchant: String
    @State private var errorMessage = ""

    private let categories = [
        "Food",
        "Transport",
        "Shopping",
        "Bills",
        "Entertainment",
        "Health",
        "Other"
    ]

    init(expense: Expense) {
        self.expense = expense
        _amount = State(initialValue: String(expense.amount))
        _category = State(
            initialValue: expense.category ?? "Food"
        )
        _merchant = State(
            initialValue: expense.merchant ?? ""
        )
    }

    var body: some View {
        Form {
            Section("Expense Information") {
                HStack {
                    Text("Amount (Rs.)")

                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { item in
                        Text(item).tag(item)
                    }
                }

                TextField("Merchant (optional)", text: $merchant)
            }

            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(Color.spendWiseDanger)
                }
            }

            Section {
                Button("Save Changes") {
                    saveChanges()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(Color.spendWiseTeal)
            }
        }
        .navigationTitle("Edit Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    private func saveChanges() {
        guard let newAmount = Double(
            amount.trimmingCharacters(in: .whitespacesAndNewlines)
        ), newAmount.isFinite, newAmount > 0 else {
            errorMessage = "Please enter a valid amount greater than zero."
            return
        }

        expense.amount = newAmount
        expense.category = category
        expense.merchant = merchant.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        // Save the updated expense to Core Data
            CoreDataService.shared.saveContext()

        // Notify HistoryView to refresh its expense list
        NotificationCenter.default.post(
                name: Notification.Name("ExpenseDidChange"),
                object: nil
        )

        // Close the edit screen
        dismiss()
    }
}

#Preview {
    NavigationStack {
        Text("Open Edit Expense from an expense detail screen.")
    }
}
