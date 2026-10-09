//
//  HistoryView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//


import SwiftUI

struct HistoryView: View {

    @StateObject private var viewModel = ExpenseViewModel()

    var body: some View {

        NavigationStack {
            VStack {
                if viewModel.expenses.isEmpty {

                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 45))
                            .foregroundColor(Color.spendWiseSecondaryText)

                        Text("No Expenses Yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.spendWiseText)

                        Text("Your saved expenses will appear here.")
                            .font(.subheadline)
                            .foregroundColor(Color.spendWiseSecondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {

                    
                    List {
                        ForEach(groupedExpenses.keys.sorted(by: >), id: \.self) { day in

                            Section {
                                ForEach(groupedExpenses[day] ?? [], id: \.objectID) { expense in

                                    HStack(spacing: 14) {

                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(Color.spendWiseTeal)

                                        VStack(alignment: .leading, spacing: 4) {

                                            Text(expense.category ?? "Other")
                                                .font(.headline)
                                                .foregroundColor(Color.spendWiseText)

                                            if let merchant = expense.merchant,
                                               !merchant.isEmpty {
                                                Text(merchant)
                                                    .font(.subheadline)
                                                    .foregroundColor(Color.spendWiseSecondaryText)
                                            }

                                            Text(expense.date ?? Date(), style: .time)
                                                .font(.caption)
                                                .foregroundColor(Color.spendWiseSecondaryText)
                                        }

                                        Spacer()

                                        Text("Rs. \(expense.amount, specifier: "%.2f")")
                                            .font(.headline)
                                            .foregroundColor(Color.spendWiseText)
                                    }
                                    .padding(.vertical, 6)
                                }
                            } header: {
                                Text(day, format: .dateTime.weekday(.wide).month().day())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.spendWiseSecondaryText)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color.spendWiseBackground)
            .navigationTitle("History")
            .onAppear {
                viewModel.fetchExpenses()
            }
        }
    }
    
    
    private var groupedExpenses: [Date: [Expense]] {

        Dictionary(grouping: viewModel.expenses) { expense in

            Calendar.current.startOfDay(
                for: expense.date ?? Date()
            )
        }
    }
    
}

#Preview {
    HistoryView()
}
