//
//  AppState.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI
import FirebaseAuth
internal import Combine

@MainActor
final class AppState: ObservableObject {

    @Published var isAuthenticated = false
    @Published var currentUserID: String?
    @Published var isSyncing = false
    @Published var syncMessage = ""

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var syncTask: Task<Void, Never>?

    init() {
        currentUserID = Auth.auth().currentUser?.uid
        isAuthenticated = currentUserID != nil

        authStateHandle = Auth.auth().addStateDidChangeListener {
            [weak self] _, user in

            Task { @MainActor in
                guard let self else { return }

                let newUserID = user?.uid

                // Ignore duplicate authentication callbacks.
                guard self.currentUserID != newUserID else {
                    return
                }

                // Cancel an earlier sync when the account changes.
                self.syncTask?.cancel()
                self.syncTask = nil

                self.currentUserID = newUserID
                self.isAuthenticated = newUserID != nil
                self.isSyncing = false
                self.syncMessage = ""

                guard newUserID != nil else {
                    return
                }

                self.syncTask = Task { @MainActor in
                    await self.syncCloudData(for: newUserID!)
                }
            }
        }
    }

    private func syncCloudData(for userID: String) async {
        guard Auth.auth().currentUser?.uid == userID else {
            return
        }

        isSyncing = true
        syncMessage = "Syncing your data..."

        defer {
            isSyncing = false
        }

        do {
            let expenses =
                try await FirestoreSyncService.shared.downloadExpenses()

            try Task.checkCancellation()
            guard Auth.auth().currentUser?.uid == userID else {
                return
            }

            let budgets =
                try await FirestoreSyncService.shared.downloadBudgets()

            try Task.checkCancellation()
            guard Auth.auth().currentUser?.uid == userID else {
                return
            }

            let categoryBudgets =
                try await FirestoreSyncService.shared
                    .downloadCategoryBudgets()

            try Task.checkCancellation()
            guard Auth.auth().currentUser?.uid == userID else {
                return
            }

            syncMessage = """
            Automatic sync completed.
            Expenses: \(expenses)
            Monthly budgets: \(budgets)
            Category budgets: \(categoryBudgets)
            """

            print(syncMessage)

        } catch is CancellationError {
            print("Automatic sync cancelled.")

        } catch {
            syncMessage = "Automatic sync failed: \(error.localizedDescription)"
            print(syncMessage)
        }
    }

    deinit {
        syncTask?.cancel()

        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }
}
