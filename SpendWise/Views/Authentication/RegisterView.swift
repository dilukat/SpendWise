//
//  RegisterView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI
import FirebaseAuth

struct RegisterView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    private let firebaseService = FirebaseService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.spendWiseTeal.opacity(0.12))
                                .frame(width: 84, height: 84)

                            Image(systemName: "wallet.bifold")
                                .font(.system(size: 38, weight: .medium))
                                .foregroundStyle(Color.spendWiseTeal)
                        }

                        VStack(spacing: 8) {
                            Text("SpendWise")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Color.spendWiseTeal)

                            Text("Create your account")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text("Start managing your personal expenses")
                                .font(.subheadline)
                                .foregroundStyle(
                                    Color.spendWiseSecondaryText
                                )
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 18) {

                        // Full Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full name")
                                .font(.subheadline.weight(.semibold))

                            HStack(spacing: 12) {
                                Image(systemName: "person")
                                    .foregroundStyle(Color.spendWiseTeal)
                                    .frame(width: 22)

                                TextField(
                                    "Enter your full name",
                                    text: $fullName
                                )
                                .textContentType(.name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(Color.spendWiseBackground)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 14)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        Color.spendWiseSecondaryText
                                            .opacity(0.25),
                                        lineWidth: 1
                                    )
                            }
                        }

                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email address")
                                .font(.subheadline.weight(.semibold))

                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundStyle(Color.spendWiseTeal)
                                    .frame(width: 22)

                                TextField(
                                    "Enter your email",
                                    text: $email
                                )
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(Color.spendWiseBackground)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 14)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        Color.spendWiseSecondaryText
                                            .opacity(0.25),
                                        lineWidth: 1
                                    )
                            }
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline.weight(.semibold))

                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .foregroundStyle(Color.spendWiseTeal)
                                    .frame(width: 22)

                                SecureField(
                                    "Create a password",
                                    text: $password
                                )
                                .textContentType(.newPassword)
                                .submitLabel(.next)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(Color.spendWiseBackground)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 14)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        Color.spendWiseSecondaryText
                                            .opacity(0.25),
                                        lineWidth: 1
                                    )
                            }
                        }

                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm password")
                                .font(.subheadline.weight(.semibold))

                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield")
                                    .foregroundStyle(Color.spendWiseTeal)
                                    .frame(width: 22)

                                SecureField(
                                    "Re-enter your password",
                                    text: $confirmPassword
                                )
                                .textContentType(.newPassword)
                                .submitLabel(.done)
                                .onSubmit {
                                    Task {
                                        await registerUser()
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(Color.spendWiseBackground)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 14)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        Color.spendWiseSecondaryText
                                            .opacity(0.25),
                                        lineWidth: 1
                                    )
                            }
                        }

                        if !errorMessage.isEmpty {
                            Label {
                                Text(errorMessage)
                                    .font(.footnote)
                            } icon: {
                                Image(
                                    systemName: "exclamationmark.circle.fill"
                                )
                            }
                            .foregroundStyle(Color.spendWiseDanger)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .padding(12)
                            .background(
                                Color.spendWiseDanger.opacity(0.08)
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 10)
                            )
                        }

                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.shield")
                                .foregroundStyle(Color.spendWiseTeal)

                            Text(
                                "By creating an account, you agree to our Terms & Privacy Policy."
                            )
                            .font(.footnote)
                            .foregroundStyle(
                                Color.spendWiseSecondaryText
                            )
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .padding(.top, 2)

                        Button {
                            Task {
                                await registerUser()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)

                                    Text("Creating Account...")
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)

                                    Image(systemName: "arrow.right")
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .foregroundStyle(.white)
                            .background(
                                isLoading
                                ? Color.spendWiseSecondaryText
                                : Color.spendWiseTeal
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                        .padding(.top, 2)
                    }

                    HStack(spacing: 5) {
                        Text("Already have an account?")
                            .foregroundStyle(
                                Color.spendWiseSecondaryText
                            )

                        Button {
                            dismiss()
                        } label: {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.spendWiseTeal)
                        }
                        .disabled(isLoading)
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .background(
                Color.spendWiseBackground.ignoresSafeArea()
            )
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @MainActor
    private func registerUser() async {
        guard !isLoading else { return }

        errorMessage = ""

        if let validationError =
            AuthenticationValidator.validateRegistration(
                fullName: fullName,
                email: email,
                password: password,
                confirmPassword: confirmPassword
            ) {
            errorMessage = validationError
            return
        }

        let trimmedName = fullName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        isLoading = true
        defer { isLoading = false }

        do {
            try await firebaseService.register(
                fullName: trimmedName,
                email: trimmedEmail,
                password: password
            )
        } catch {
            errorMessage = FirebaseAuthErrorMapper.registrationMessage(
                for: error
            )
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AppState())
}
