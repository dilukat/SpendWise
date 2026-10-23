//
//  ExpenseSyncMonitor.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-23.
//

import Foundation
internal import Combine
import FirebaseAuth

@MainActor
final class ExpenseSyncMonitor: ObservableObject {
    static let shared = ExpenseSyncMonitor()

    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private var isSyncing = false

    private init() {
        networkMonitor.$isConnected
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.syncPendingExpenses()
                }
            }
            .store(in: &cancellables)
    }

    func syncPendingExpenses() async {
        guard networkMonitor.isConnected else { return }
        guard Auth.auth().currentUser != nil else { return }
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            // Upload pending expenses.
            let uploadedExpenses = try await FirestoreSyncService.shared
                .uploadPendingExpenses()

            print("Automatic sync: \(uploadedExpenses) pending expenses uploaded.")

            // Upload local monthly and category budgets.
            let budgetResult = try await FirestoreSyncService.shared
                .uploadLocalBudgetsAndCategoryBudgets()

            print("Automatic sync: \(budgetResult.budgets) monthly budgets uploaded.")
            print("Automatic sync: \(budgetResult.categoryBudgets) category budgets uploaded.")
        } catch {
            print(
                "Automatic expense sync failed: \(error.localizedDescription)"
            )
        }
    }
}

