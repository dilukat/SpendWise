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
    
    @AppStorage("dailyReminderEnabled")
    private var dailyReminderEnabled = false

    @AppStorage("dailyReminderHour")
    private var dailyReminderHour = 20

    @AppStorage("dailyReminderMinute")
    private var dailyReminderMinute = 0

    @State private var selectedReminderTime = Calendar.current.date(
        from: DateComponents(hour: 20, minute: 0)
    ) ?? Date()

    private let firebaseService = FirebaseService.shared

    var body: some View {

        NavigationStack {

            Form {
            
                // MARK: - Account

                Section("Account") {

                    Button(role: .destructive) {

                        showLogoutConfirmation = true

                    } label: {

                        HStack {

                            Image(systemName: "rectangle.portrait.and.arrow.right")

                            Text("Log Out")
                        }
                    }
                }
                
                Section("Daily Spending Reminder") {
                    Toggle(
                        "Enable Daily Reminder",
                        isOn: $dailyReminderEnabled
                    )
                    .onChange(of: dailyReminderEnabled) { _, isEnabled in
                        Task {
                            if isEnabled {
                                let granted = await NotificationService.shared
                                    .requestPermission()

                                guard granted else {
                                    dailyReminderEnabled = false
                                    return
                                }

                                let scheduled = await NotificationService.shared
                                    .scheduleDailyReminder(
                                        hour: dailyReminderHour,
                                        minute: dailyReminderMinute
                                    )

                                if !scheduled {
                                    dailyReminderEnabled = false
                                }
                            } else {
                                NotificationService.shared.cancelDailyReminder()
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
                                let scheduled = await NotificationService.shared
                                    .scheduleDailyReminder(
                                        hour: dailyReminderHour,
                                        minute: dailyReminderMinute
                                    )

                                if !scheduled {
                                    print("Unable to update daily reminder.")
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
                        let scheduled = await NotificationService.shared
                            .scheduleDailyReminder(
                                hour: dailyReminderHour,
                                minute: dailyReminderMinute
                            )

                        if !scheduled {
                            print("Unable to restore daily reminder.")
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

                Button("Cancel", role: .cancel) {
                }

            } message: {

                Text("Are you sure you want to log out?")
            }
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

#Preview {
    SettingsView()
}
