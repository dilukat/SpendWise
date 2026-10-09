//
//  HistoryView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//


import SwiftUI

struct HistoryView: View {

    @StateObject private var viewModel = ExpenseViewModel()
    @State private var searchText = ""
    @State private var selectedCategory = "All"

    var body: some View {

        NavigationStack {
            VStack {
                
                HStack {
                    Text("Category")
                        .font(.subheadline)
                        .foregroundColor(Color.spendWiseSecondaryText)

                    Spacer()

                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories")
                            .tag("All")

                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if filteredExpenses.isEmpty {

                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 45))
                            .foregroundColor(Color.spendWiseSecondaryText)

                        Text(searchText.isEmpty ? "No Expenses Yet" : "No Matching Expenses")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.spendWiseText)

                        Text(
                            searchText.isEmpty
                                ? "Your saved expenses will appear here."
                                : "Try another category or merchant name."
                        )
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
            .searchable(
                text: $searchText,
                prompt: "Search category or merchant"
            )
            .onAppear {
                viewModel.fetchExpenses()
            }
        }
    }
    
    
    
    
    private var filteredExpenses: [Expense] {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return viewModel.expenses.filter { expense in
            let category = expense.category ?? ""
            let merchant = expense.merchant ?? ""

            let matchesSearch = query.isEmpty
                || category.localizedCaseInsensitiveContains(query)
                || merchant.localizedCaseInsensitiveContains(query)

            let matchesCategory = selectedCategory == "All"
                || category.caseInsensitiveCompare(selectedCategory) == .orderedSame

            return matchesSearch && matchesCategory
        }
    }

    private var groupedExpenses: [Date: [Expense]] {

        Dictionary(grouping: filteredExpenses) { expense in

            Calendar.current.startOfDay(
                for: expense.date ?? Date()
            )
        }
    }
    
}

#Preview {
    HistoryView()
}
