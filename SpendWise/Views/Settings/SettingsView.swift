//
//  SettingsView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var appState: AppState

    // MARK: - Logout

    @State private var showLogoutConfirmation = false

    // MARK: - Cloud Sync

    @State private var isSyncingExpenses = false
    @State private var syncMessage = ""
    @State private var syncError = false

    // MARK: - Daily Reminder

    @AppStorage("dailyReminderEnabled")
    private var dailyReminderEnabled = false

    @AppStorage("dailyReminderHour")
    private var dailyReminderHour = 20

    @AppStorage("dailyReminderMinute")
    private var dailyReminderMinute = 0

    @State private var selectedReminderTime = Calendar.current.date(
        from: DateComponents(hour: 20, minute: 0)
    ) ?? Date()

    // MARK: - Face ID

    @AppStorage("faceIDEnabled")
    private var faceIDEnabled = false

    @State private var faceIDMessage = ""

    private let firebaseService = FirebaseService.shared

    // MARK: - View

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Account & Sync

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

                // MARK: Security

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

                // MARK: Daily Spending Reminder

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

    // MARK: - Sync All Data

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
            let uploadedCount = try await FirestoreSyncService.shared.uploadPendingExpenses()
            print("Pending expenses uploaded: \(uploadedCount)")
            
            let expenseCount =
                try await FirestoreSyncService.shared.downloadExpenses()

            let budgetCount =
                try await FirestoreSyncService.shared.downloadBudgets()

            let categoryBudgetCount =
                try await FirestoreSyncService.shared
                    .downloadCategoryBudgets()

            syncMessage = """
            Sync completed successfully.

            Expenses: \(expenseCount)
            Monthly budgets: \(budgetCount)
            Category budgets: \(categoryBudgetCount)
            """

            print(syncMessage)

        } catch {
            syncMessage =
                "Sync failed: \(error.localizedDescription)"

            syncError = true

            print("Cloud sync error: \(error.localizedDescription)")
        }
    }

    // MARK: - Logout

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

