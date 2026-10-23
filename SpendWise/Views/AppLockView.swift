//
//  AppLockView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-20.
//


import SwiftUI

struct AppLockView: View {
    let onUnlock: () -> Void

    @State private var isAuthenticating = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 70))
                .foregroundStyle(Color.spendWiseTeal)

            Text("SpendWise is Locked")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.spendWiseText)

            Text("Authenticate with Face ID to access your expenses.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.spendWiseSecondaryText)

            Button {
                authenticate()
            } label: {
                Label("Unlock with Face ID", systemImage: "faceid")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.spendWiseTeal)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isAuthenticating)
            .padding(.horizontal, 24)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.spendWiseDanger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.spendWiseBackground.ignoresSafeArea())
        .task {
            authenticate()
        }
    }

    private func authenticate() {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        errorMessage = ""

        Task {
            let authenticated =
                await BiometricAuthService.shared.authenticate()

            await MainActor.run {
                isAuthenticating = false

                if authenticated {
                    onUnlock()
                } else {
                    errorMessage =
                        "Authentication failed. Please try again."
                }
            }
        }
    }
}
