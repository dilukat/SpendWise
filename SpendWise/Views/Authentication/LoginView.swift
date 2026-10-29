//
//  LoginView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {

    @EnvironmentObject var appState: AppState

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showRegister = false

    private let firebaseService = FirebaseService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {

                    VStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.spendWiseTeal.opacity(0.12))
                                .frame(width: 84, height: 84)

                            Image(systemName: "wallet.bifold")
                                .font(.system(size: 38, weight: .medium))
                                .foregroundStyle(Color.spendWiseTeal)
                        }
                        .padding(.top , 70)

                        VStack(spacing: 8) {
                            Text("SpendWise")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Color.spendWiseTeal)

                            Text("Manage your money smarter")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text("Sign in to access your finances")
                                .font(.subheadline)
                                .foregroundStyle(
                                    Color.spendWiseSecondaryText
                                )
                        }
                        .multilineTextAlignment(.center)
                    }
                    .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 20) {

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email address")
                                .font(.subheadline.weight(.semibold))

                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundStyle(
                                        Color.spendWiseTeal
                                    )
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
                            .background(
                                Color.spendWiseBackground
                            )
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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline.weight(.semibold))

                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .foregroundStyle(
                                        Color.spendWiseTeal
                                    )
                                    .frame(width: 22)

                                SecureField(
                                    "Enter your password",
                                    text: $password
                                )
                                .textContentType(.password)
                                .submitLabel(.done)
                                .onSubmit {
                                    Task {
                                        await loginUser()
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(
                                Color.spendWiseBackground
                            )
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
                                Image(systemName: "exclamationmark.circle.fill")
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

                        Button {
                            Task {
                                await loginUser()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)

                                    Text("Signing In...")
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Sign In")
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
                        .padding(.top, 4)
                    }

                    HStack(spacing: 5) {
                        Text("Don't have an account?")
                            .foregroundStyle(
                                Color.spendWiseSecondaryText
                            )

                        Button {
                            showRegister = true
                        } label: {
                            Text("Create Account")
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
            .background(Color.spendWiseBackground.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showRegister) {
                RegisterView()
                    .environmentObject(appState)
            }
        }
    }

    @MainActor
    private func loginUser() async {
        guard !isLoading else { return }

        errorMessage = ""

        if let validationError = AuthenticationValidator.validateLogin(
            email: email,
            password: password
        ) {
            errorMessage = validationError
            return
        }

        let trimmedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        isLoading = true
        defer { isLoading = false }

        do {
            try await firebaseService.login(
                email: trimmedEmail,
                password: password
            )

            print("Login successful. User authenticated.")

        } catch {
            errorMessage = FirebaseAuthErrorMapper.loginMessage(
                for: error
            )
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
