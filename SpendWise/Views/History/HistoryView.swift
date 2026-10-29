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

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {

        NavigationStack {

            VStack(alignment: .leading, spacing: 6) {

//                HStack {
//                    Text("History")
//                        .font(.title)
//                        .fontWeight(.bold)
//                        .foregroundColor(Color.spendWiseText)
//
//                    Spacer()
//                }
//                .padding(.horizontal)
//                .padding()

                HStack(spacing: 10) {

                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.spendWiseSecondaryText)
                        .font(.system(size: 18))

                    TextField(
                        "Search category or merchant",
                        text: $searchText
                    )
                    .font(.body)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(
                                    Color.spendWiseSecondaryText
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.spendWiseCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
                .padding(.bottom, 10)

                HStack {

                    Text("Category")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.spendWiseSecondaryText)

                    Spacer()

                    Picker(
                        "Category",
                        selection: $selectedCategory
                    ) {

                        Text("All Categories")
                            .tag("All")

                        ForEach(
                            viewModel.categories,
                            id: \.self
                        ) { category in
                            Text(category)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.spendWiseTeal)
                }
                .padding(.horizontal)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

                if filteredExpenses.isEmpty {

                    VStack(spacing: 12) {

                        Image(systemName: "tray")
                            .font(.system(size: 45))
                            .foregroundColor(
                                Color.spendWiseSecondaryText
                            )

                        Text(
                            searchText.isEmpty
                                ? "No Expenses Yet"
                                : "No Matching Expenses"
                        )
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.spendWiseText)

                        Text(
                            searchText.isEmpty
                                ? "Your saved expenses will appear here."
                                : "Try another category or merchant name."
                        )
                        .font(.subheadline)
                        .foregroundColor(
                            Color.spendWiseSecondaryText
                        )
                        .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )

                } else {

                    List {

                        ForEach(
                            groupedExpenses.keys.sorted(by: >),
                            id: \.self
                        ) { day in

                            Section {

                                ForEach(
                                    groupedExpenses[day] ?? [],
                                    id: \.objectID
                                ) { expense in

                                    NavigationLink {

                                        ExpenseDetailView(
                                            expense: expense
                                        )
                                        .onDisappear {
                                            viewModel.fetchExpenses()
                                        }

                                    } label: {

                                        HStack(spacing: 14) {

                                            Image(
                                                systemName:
                                                    "arrow.down.circle.fill"
                                            )
                                            .font(.title2)
                                            .foregroundColor(
                                                Color.spendWiseTeal
                                            )

                                            VStack(
                                                alignment: .leading,
                                                spacing: 4
                                            ) {

                                                Text(
                                                    expense.category ?? "Other"
                                                )
                                                .font(.headline)
                                                .foregroundColor(
                                                    Color.spendWiseText
                                                )

                                                if let merchant = expense.merchant,
                                                   !merchant.isEmpty {

                                                    Text(merchant)
                                                        .font(.subheadline)
                                                        .foregroundColor(
                                                            Color.spendWiseSecondaryText
                                                        )
                                                        .lineLimit(2)
                                                }

                                                Text(
                                                    expense.date ?? Date(),
                                                    style: .time
                                                )
                                                .font(.caption)
                                                .foregroundColor(
                                                    Color.spendWiseSecondaryText
                                                )
                                            }

                                            Spacer(minLength: 8)

                                            Text(
                                                "Rs. \(expense.amount, specifier: "%.2f")"
                                            )
                                            .font(.headline)
                                            .foregroundColor(
                                                Color.spendWiseText
                                            )
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                        }
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.plain)
                                }

                            } header: {

                                Text(
                                    day,
                                    format: .dateTime
                                        .weekday(.wide)
                                        .month()
                                        .day()
                                )
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(
                                    Color.spendWiseSecondaryText
                                )
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.spendWiseBackground)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Text("History")
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
                viewModel.fetchExpenses()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: Notification.Name("ExpenseDidChange")
                )
            ) { _ in
                viewModel.fetchExpenses()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.fetchExpenses()
                }
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
                || category.caseInsensitiveCompare(
                    selectedCategory
                ) == .orderedSame

            return matchesSearch && matchesCategory
        }
    }

    private var groupedExpenses: [Date: [Expense]] {

        Dictionary(
            grouping: filteredExpenses
        ) { expense in

            Calendar.current.startOfDay(
                for: expense.date ?? Date()
            )
        }
    }
}

#Preview {
    HistoryView()
}
