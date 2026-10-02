//
//  HomeView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI
internal import CoreData

struct HomeView: View {

    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                Text("Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("SpendWise Dashboard")
                    .foregroundStyle(Color.spendWiseSecondaryText)

                Spacer()
            }
            .padding()
            .background(Color.spendWiseBackground)
            .navigationTitle("SpendWise")
            
            Button("Test Delete Expense") {
                testDeleteExpense()
            }
            
            Button("Test Fetch Expense") {
                testFetchExpense()
            }
            
            Button("Test Save Expense") {
                testSaveExpense()
            }
        }
    }
    
    private func testSaveExpense() {

        let context = CoreDataService.shared.viewContext

        let expense = Expense(context: context)

        expense.expenseID = UUID().uuidString
        expense.amount = 2500
        expense.category = "Food"
        expense.merchant = "Test Merchant"
        expense.date = Date()
        expense.latitude = 6.9271
        expense.longitude = 79.8612
        expense.budgetID = UUID().uuidString

        CoreDataService.shared.saveContext()

        print("Test expense saved successfully.")
    }
    
    private func testFetchExpense() {

        let context = CoreDataService.shared.viewContext

        let request = Expense.fetchRequest()

        do {

            let expenses = try context.fetch(request)

            print("Total expenses found: \(expenses.count)")

            for expense in expenses {

                print("Expense ID: \(expense.expenseID ?? "No ID")")
                print("Amount: \(expense.amount)")
                print("Category: \(expense.category ?? "No Category")")
                print("Merchant: \(expense.merchant ?? "No Merchant")")
            }

        } catch {

            print("Core Data fetch error: \(error.localizedDescription)")
        }
    }
    
    private func testDeleteExpense() {

        let context = CoreDataService.shared.viewContext

        let request = Expense.fetchRequest()

        do {

            let expenses = try context.fetch(request)

            if let expense = expenses.first {

                context.delete(expense)

                CoreDataService.shared.saveContext()

                print("Test expense deleted successfully.")

            } else {

                print("No expenses found to delete.")
            }

        } catch {

            print("Core Data delete error: \(error.localizedDescription)")
        }
    }
    
}
#Preview {
    HomeView()
}
