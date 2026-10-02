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
