//
//  SettingsView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var appState: AppState

    @State private var showLogoutConfirmation = false

    @State private var isSyncingExpenses = false
    @State private var syncMessage = ""
    @State private var syncError = false

    @AppStorage("dailyReminderEnabled")
    private var dailyReminderEnabled = false

    @AppStorage("dailyReminderHour")
    private var dailyReminderHour = 20

    @AppStorage("dailyReminderMinute")
    private var dailyReminderMinute = 0

    @State private var selectedReminderTime = Calendar.current.date(
        from: DateComponents(hour: 20, minute: 0)
    ) ?? Date()

    @AppStorage("faceIDEnabled")
    private var faceIDEnabled = false

    @State private var faceIDMessage = ""

    private let firebaseService = FirebaseService.shared

    var body: some View {
        NavigationStack {
            Form {

                // Account & Sync
                Section("Account") {

                    
                    Button {
                        Task {
                            await syncAllData()
                        }
                    } label: {
                        Label {
                            Text("Sync Now")
                        } icon: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(Color.spendWiseTeal)
                                .frame(width: 24, alignment: .leading)
                        }
                    }
                    .disabled(isSyncingExpenses)


                    if !syncMessage.isEmpty {
                        Text(syncMessage)
                            .font(.caption)
                            .foregroundStyle(
                                syncError
                                    ? Color.red
                                    : Color.spendWiseSecondaryText
                            )
                            .textSelection(.enabled)
                    }
                    
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        Label {
                            Text("Log Out")
                                .foregroundStyle(.red)
                        } icon: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.red)
                                .frame(width: 24, alignment: .leading)
                        }
                    }

                }

                // Security

                Section("Security") {
                    Toggle(
                        "Face ID Protection",
                        isOn: Binding(
                            get: { faceIDEnabled },
                            set: { newValue in
                                guard newValue else {
                                    faceIDEnabled = false
                                    faceIDMessage =
                                        "Face ID protection disabled."
                                    return
                                }

                                guard !faceIDEnabled else {
                                    return
                                }

                                let service = BiometricAuthService.shared

                                guard service.isBiometricAvailable() else {
                                    faceIDMessage =
                                        "Face ID is not available."
                                    return
                                }

                                Task { @MainActor in
                                    let authenticated =
                                        await service.authenticate()

                                    if authenticated {
                                        faceIDEnabled = true
                                        faceIDMessage =
                                            "Face ID protection enabled."
                                    } else {
                                        faceIDEnabled = false
                                        faceIDMessage =
                                            "Authentication failed. Please try again."
                                    }
                                }
                            }
                        )
                    )

                    if !faceIDMessage.isEmpty {
                        Text(faceIDMessage)
                            .font(.caption)
                            .foregroundStyle(
                                Color.spendWiseSecondaryText
                            )
                    }
                }

                // Daily Spending Reminder

                Section("Daily Spending Reminder") {
                    Toggle(
                        "Enable Daily Reminder",
                        isOn: $dailyReminderEnabled
                    )
                    .onChange(of: dailyReminderEnabled) { _, isEnabled in
                        Task {
                            if isEnabled {
                                let granted =
                                    await NotificationService.shared
                                        .requestPermission()

                                guard granted else {
                                    dailyReminderEnabled = false
                                    return
                                }

                                let scheduled =
                                    await NotificationService.shared
                                        .scheduleDailyReminder(
                                            hour: dailyReminderHour,
                                            minute: dailyReminderMinute
                                        )

                                if !scheduled {
                                    dailyReminderEnabled = false
                                }
                            } else {
                                NotificationService.shared
                                    .cancelDailyReminder()
                            }
                        }
                    }

                    if dailyReminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $selectedReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: selectedReminderTime) { _, newTime in
                            let components = Calendar.current.dateComponents(
                                [.hour, .minute],
                                from: newTime
                            )

                            dailyReminderHour = components.hour ?? 20
                            dailyReminderMinute = components.minute ?? 0

                            Task {
                                let scheduled =
                                    await NotificationService.shared
                                        .scheduleDailyReminder(
                                            hour: dailyReminderHour,
                                            minute: dailyReminderMinute
                                        )

                                if !scheduled {
                                    print(
                                        "Unable to update daily reminder."
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                var components = DateComponents()
                components.hour = dailyReminderHour
                components.minute = dailyReminderMinute

                selectedReminderTime = Calendar.current.date(
                    from: components
                ) ?? Date()

                if dailyReminderEnabled {
                    Task {
                        let scheduled =
                            await NotificationService.shared
                                .scheduleDailyReminder(
                                    hour: dailyReminderHour,
                                    minute: dailyReminderMinute
                                )

                        if !scheduled {
                            print(
                                "Unable to restore daily reminder."
                            )
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Log Out",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Log Out", role: .destructive) {
                    logout()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }

    // Sync All Data

    
    @MainActor
    private func syncAllData() async {
        guard !isSyncingExpenses else {
            return
        }

        isSyncingExpenses = true
        syncMessage = "Syncing your data..."
        syncError = false

        defer {
            isSyncingExpenses = false
        }

        do {
            // 1. Upload & delete pending expenses.
            let deletedCount = try await FirestoreSyncService.shared
                .syncPendingExpenseDeletions()

            print("Pending expense deletions completed: \(deletedCount)")

            let uploadedCount = try await FirestoreSyncService.shared
                .uploadPendingExpenses()

            print("Pending expenses uploaded: \(uploadedCount)")

            // 2. Upload local monthly and category budgets.
            let budgetUploadResult =
                try await FirestoreSyncService.shared
                    .uploadLocalBudgetsAndCategoryBudgets()

            print("Monthly budgets uploaded: \(budgetUploadResult.budgets)")
            print("Category budgets uploaded: \(budgetUploadResult.categoryBudgets)")

            // 3. Download the latest cloud data.
            let expenseCount =
                try await FirestoreSyncService.shared.downloadExpenses()

            let budgetCount =
                try await FirestoreSyncService.shared.downloadBudgets()

            let categoryBudgetCount =
                try await FirestoreSyncService.shared.downloadCategoryBudgets()

            syncMessage = """
            Sync completed successfully.

            Expenses downloaded: \(expenseCount)
            Monthly budgets uploaded: \(budgetUploadResult.budgets)
            Category budgets uploaded: \(budgetUploadResult.categoryBudgets)
            Monthly budgets downloaded: \(budgetCount)
            Category budgets downloaded: \(categoryBudgetCount)
            """

            print(syncMessage)

        } catch {
            syncMessage = "Sync failed: \(error.localizedDescription)"
            syncError = true

            print("Cloud sync error: \(error.localizedDescription)")
        }
    }


    // Logout

    private func logout() {
        do {
            try firebaseService.logout()
        } catch {
            print("Logout failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}

