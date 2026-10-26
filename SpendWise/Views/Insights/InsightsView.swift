//
//  InsightsView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//
 
import SwiftUI
import Charts
import MapKit
internal import CoreData

struct InsightsView: View {

    @StateObject private var expenseViewModel = ExpenseViewModel()
    @StateObject private var budgetViewModel = BudgetViewModel()
    @State private var selectedMonth = Date()
    
    @State private var selectedLocationExpenseID: String?
    @State private var isShowingLocationDetails = false

    private let calendar = Calendar.current

    private var selectedMonthTitle: String {
        selectedMonth.formatted(
            .dateTime.month(.wide).year()
        )
    }

    private var canGoToNextMonth: Bool {
        guard let nextMonth = calendar.date(
            byAdding: .month,
            value: 1,
            to: selectedMonth
        ) else {
            return false
        }

        return calendar.compare(
            nextMonth,
            to: Date(),
            toGranularity: .month
        ) != .orderedDescending
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(
            byAdding: .month,
            value: value,
            to: selectedMonth
        ) else {
            return
        }

        guard calendar.compare(
            newMonth,
            to: Date(),
            toGranularity: .month
        ) != .orderedDescending else {
            return
        }

        selectedMonth = newMonth
    }

    private var monthExpenses: [Expense] {
        guard
            let startOfMonth = calendar.date(
                from: calendar.dateComponents(
                    [.year, .month],
                    from: selectedMonth
                )
            ),
            let startOfNextMonth = calendar.date(
                byAdding: .month,
                value: 1,
                to: startOfMonth
            )
        else {
            return []
        }

        return expenseViewModel.expenses.filter { expense in
            guard let date = expense.date else { return false }
            return date >= startOfMonth && date < startOfNextMonth
        }
    }
    
    private var expensesWithLocation: [Expense] {
        monthExpenses.filter { expense in
            let latitude = expense.latitude
            let longitude = expense.longitude

            // Exclude expenses without valid saved coordinates.
            guard latitude != 0 || longitude != 0 else {
                return false
            }

            guard (-90...90).contains(latitude),
                  (-180...180).contains(longitude) else {
                return false
            }

            return true
        }
    }

    private var totalSpent: Double {
        monthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var expenseCount: Int {
        monthExpenses.count
    }

    private var highestSpendingCategory: (category: String, amount: Double)? {
        categoryTotals.first
    }

    private var averageDailySpending: Double {
        let daysElapsed: Int

        if calendar.isDate(
            selectedMonth,
            equalTo: Date(),
            toGranularity: .month
        ) {
            daysElapsed = calendar.component(.day, from: Date())
        } else if selectedMonth < Date() {
            daysElapsed = calendar.range(
                of: .day,
                in: .month,
                for: selectedMonth
            )?.count ?? 1
        } else {
            daysElapsed = 1
        }

        guard daysElapsed > 0 else { return 0 }

        return totalSpent / Double(daysElapsed)
    }

    
    private var selectedMonthBudget: Budget? {
        budgetViewModel.budgets.first { budget in
            Int(budget.month) == calendar.component(.month, from: selectedMonth) &&
            Int(budget.year) == calendar.component(.year, from: selectedMonth)
        }
    }

    private var budgetAmount: Double {
        selectedMonthBudget?.totalAmount ?? 0
    }

    private var remainingBudget: Double {
        budgetAmount - totalSpent
    }

    private var budgetProgress: Double {
        guard budgetAmount > 0 else { return 0 }
        return min(max(totalSpent / budgetAmount, 0), 1)
    }

    private var budgetPercentageUsed: Int {
        guard budgetAmount > 0 else { return 0 }
        return Int((totalSpent / budgetAmount * 100).rounded())
    }
    
    private var dailySpending: [(day: Date, amount: Double)] {
        let grouped = Dictionary(
            grouping: monthExpenses.compactMap { expense -> (Date, Double)? in
                guard let date = expense.date else {
                    return nil
                }

                let day = calendar.startOfDay(for: date)
                return (day, expense.amount)
            },
            by: { $0.0 }
        )

        guard let startOfMonth = calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: selectedMonth
            )
        ),
        let numberOfDays = calendar.range(
            of: .day,
            in: .month,
            for: selectedMonth
        ) else {
            return []
        }

        return numberOfDays.compactMap { dayNumber in
            guard let day = calendar.date(
                byAdding: .day,
                value: dayNumber - 1,
                to: startOfMonth
            ) else {
                return nil
            }

            let amount = grouped[day, default: []].reduce(0.0) {
                $0 + $1.1
            }

            return (day: day, amount: amount)
        }
    }


    private var categoryTotals: [(category: String, amount: Double)] {
        let totals = Dictionary(
            grouping: monthExpenses,
            by: { $0.category ?? "Other" }
        )
        .mapValues { expenses in
            expenses.reduce(0) { $0 + $1.amount }
        }

        return totals
            .map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Monthly overview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Spending")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack {
                            Button {
                                changeMonth(by: -1)
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Color(.secondarySystemBackground)
                                    )
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Previous month")

                            Spacer()

                            Text(selectedMonthTitle)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)

                            Spacer()

                            Button {
                                changeMonth(by: 1)
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Color(.secondarySystemBackground)
                                    )
                                    .clipShape(Circle())
                            }
                            .disabled(!canGoToNextMonth)
                            .opacity(canGoToNextMonth ? 1 : 0.35)
                            .accessibilityLabel("Next month")
                        }

                        Text("Total spent")
                            .foregroundStyle(
                                Color.spendWiseSecondaryText
                            )

                        Text(
                            totalSpent,
                            format: .currency(code: "LKR")
                        )
                        .font(.system(
                            size: 32,
                            weight: .bold
                        ))
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Budget Progress")
                            .font(.headline)

                        if budgetAmount <= 0 {
                            ContentUnavailableView(
                                "No Budget Set",
                                systemImage: "chart.pie",
                                description: Text(
                                    "Set a monthly budget to track your spending progress."
                                )
                            )
                            .frame(minHeight: 140)
                        } else {
                            HStack(alignment: .firstTextBaseline) {
                                Text("Budget used")
                                    .foregroundStyle(Color.spendWiseSecondaryText)

                                Spacer()

                                Text("\(budgetPercentageUsed)%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }

                            ProgressView(value: budgetProgress)
                                .tint(
                                    totalSpent > budgetAmount
                                        ? .red
                                        : Color.spendWiseTeal
                                )

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Spent")
                                        .font(.caption)
                                        .foregroundStyle(Color.spendWiseSecondaryText)

                                    Text(
                                        totalSpent,
                                        format: .currency(code: "LKR")
                                    )
                                    .fontWeight(.semibold)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(remainingBudget < 0 ? "Over budget" : "Remaining")
                                        .font(.caption)
                                        .foregroundStyle(Color.spendWiseSecondaryText)

                                    Text(
                                        abs(remainingBudget),
                                        format: .currency(code: "LKR")
                                    )
                                    .fontWeight(.semibold)
                                    .foregroundStyle(
                                        remainingBudget < 0 ? .red : .primary
                                    )
                                }
                            }

                            Text(
                                "Monthly limit: \(budgetAmount.formatted(.currency(code: "LKR")))"
                            )
                            .font(.caption)
                            .foregroundStyle(Color.spendWiseSecondaryText)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Spending Summary")
                            .font(.headline)

                        HStack(alignment: .top, spacing: 12) {
                            summaryMetric(
                                title: "Expenses",
                                value: "\(expenseCount)",
                                icon: "receipt"
                            )

                            summaryMetric(
                                title: "Daily Average",
                                value: averageDailySpending.formatted(
                                    .currency(code: "LKR")
                                ),
                                icon: "calendar"
                            )
                        }

                        if let highest = highestSpendingCategory {
                            HStack(spacing: 12) {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundStyle(Color.spendWiseTeal)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Color.spendWiseTeal.opacity(0.12)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Highest-Spending Category")
                                        .font(.caption)
                                        .foregroundStyle(Color.spendWiseSecondaryText)

                                    Text(highest.category)
                                        .fontWeight(.semibold)
                                }

                                Spacer()

                                Text(
                                    highest.amount,
                                    format: .currency(code: "LKR")
                                )
                                .fontWeight(.semibold)
                            }
                        } else {
                            Text("No expenses recorded for this month.")
                                .font(.subheadline)
                                .foregroundStyle(Color.spendWiseSecondaryText)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    
                    
                    

                    // Category chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Spending by Category")
                            .font(.headline)

                        if categoryTotals.isEmpty {
                            ContentUnavailableView(
                                "No Spending Yet",
                                systemImage: "chart.bar",
                                description: Text(
                                    "Add expenses for this month to see your category breakdown."
                                )
                            )
                            .frame(minHeight: 180)
                        } else {
                            Chart(categoryTotals, id: \.category) { item in
                                BarMark(
                                    x: .value(
                                        "Amount",
                                        item.amount
                                    ),
                                    y: .value(
                                        "Category",
                                        item.category
                                    )
                                )
                                .foregroundStyle(
                                    Color.spendWiseTeal
                                )
                                .annotation(position: .trailing) {
                                    Text(
                                        item.amount,
                                        format: .number.precision(
                                            .fractionLength(0)
                                        )
                                    )
                                    .font(.caption2)
                                    .foregroundStyle(
                                        Color.spendWiseSecondaryText
                                    )
                                }
                            }
                            .chartXAxis {
                                AxisMarks(position: .bottom)
                            }
                            .frame(
                                height: CGFloat(
                                    max(categoryTotals.count, 1) * 48
                                )
                            )
                        }
                    }
                    .padding()
                    .background(
                        Color(.secondarySystemBackground)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 20)
                    )
                    
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Spending Trend")
                            .font(.headline)

                        if monthExpenses.isEmpty {
                            ContentUnavailableView(
                                "No Spending Yet",
                                systemImage: "chart.xyaxis.line",
                                description: Text(
                                    "Add expenses to see your daily spending trend."
                                )
                            )
                            .frame(minHeight: 180)
                        } else {
                            Chart(dailySpending, id: \.day) { item in
                                LineMark(
                                    x: .value("Day", item.day),
                                    y: .value("Amount", item.amount)
                                )
                                .foregroundStyle(Color.spendWiseTeal)
                                .interpolationMethod(.linear)

                                AreaMark(
                                    x: .value("Day", item.day),
                                    y: .value("Amount", item.amount)
                                )
                                .foregroundStyle(
                                    Color.spendWiseTeal.opacity(0.12)
                                )
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: 5)) { value in
                                    AxisValueLabel(format: .dateTime.day())
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 220)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    
                }
                .padding()
                
                
                // Expense Locations Map
                VStack(alignment: .leading, spacing: 16) {
                    Text("Expense Locations")
                        .font(.headline)

                    if expensesWithLocation.isEmpty {
                        ContentUnavailableView(
                            "No Expense Locations",
                            systemImage: "map",
                            description: Text(
                                "No expenses with saved coordinates were found for \(selectedMonthTitle)."
                            )
                        )
                        .frame(minHeight: 180)
                    } else {
                        Map {
                            ForEach(
                                expensesWithLocation,
                                id: \.objectID
                            ) { expense in
                                Annotation(
                                    expense.merchant ?? "Expense",
                                    coordinate: CLLocationCoordinate2D(
                                        latitude: expense.latitude,
                                        longitude: expense.longitude
                                    )
                                ) {
                                    Button {
                                        selectedLocationExpenseID =
                                            expense.objectID.uriRepresentation()
                                                .absoluteString
                                        isShowingLocationDetails = true
                                    } label: {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title)
                                            .foregroundStyle(Color.spendWiseTeal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .sheet(isPresented: $isShowingLocationDetails) {
                            if let expense = expensesWithLocation.first(
                                where: {
                                    $0.objectID.uriRepresentation()
                                        .absoluteString == selectedLocationExpenseID
                                }
                            ) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(expense.merchant ?? "Expense")
                                        .font(.title2)
                                        .fontWeight(.bold)

                                    Text(
                                        expense.amount,
                                        format: .currency(code: "LKR")
                                    )
                                    .font(.title3)

                                    Text("Category: \(expense.category ?? "Other")")

                                    if let date = expense.date {
                                        Text(date.formatted(date: .abbreviated, time: .shortened))
                                    }

                                    Text(
                                        "Latitude: \(expense.latitude.formatted())"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                    Text(
                                        "Longitude: \(expense.longitude.formatted())"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                    Spacer()
                                }
                                .padding()
                                .presentationDetents([.medium])
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            }
            .background(Color.spendWiseBackground)
            .navigationTitle("Insights")
            .onAppear {
                expenseViewModel.fetchExpenses()
                budgetViewModel.refreshData()
            }
            .onChange(of: selectedMonth) { _, _ in
                expenseViewModel.fetchExpenses()
            }
        }
    }
    
    private func summaryMetric(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.spendWiseTeal)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.spendWiseSecondaryText)

            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.spendWiseBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

}

#Preview {
    InsightsView()
}

