//
//  EditExpenseView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-13.
//


import SwiftUI
import FirebaseAuth

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

        guard let userID = FirebaseService.shared.currentUser?.uid,
              expense.userID == userID else {
            errorMessage = "Please log in to update this expense."
            return
        }

        expense.amount = newAmount
        expense.category = category
        expense.merchant = merchant.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        expense.isSynced = false

        // Save the changes locally first.
        CoreDataService.shared.saveContext()

        // Recheck the monthly budget threshold.
        ExpenseViewModel().checkCurrentMonthBudgetAlert()

        // Notify views that the expense has changed.
        NotificationCenter.default.post(
            name: Notification.Name("ExpenseDidChange"),
            object: nil
        )

        // Upload the updated expense.
        Task { @MainActor in
            do {
                try await FirestoreSyncService.shared.uploadExpense(expense)

                // Mark synced only after the cloud upload succeeds.
                expense.isSynced = true
                CoreDataService.shared.saveContext()

                print("Expense updated and synced to Firestore.")
                dismiss()
            } catch {
                errorMessage =
                    "Changes saved locally, but cloud sync failed: \(error.localizedDescription)"
                print("Expense update sync failed: \(error.localizedDescription)")
            }
        }
    }

}

#Preview {
    NavigationStack {
        Text("Open Edit Expense from an expense detail screen.")
    }
}
