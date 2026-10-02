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

                VStack(spacing: 24) {

                    // MARK: - Header

                    VStack(spacing: 8) {

                        Text("SpendWise")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.spendWiseTeal)

                        Text("Manage your money smarter")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundStyle(Color.spendWiseSecondaryText)
                    }
                    .padding(.top, 40)

                    // MARK: - Login Fields

                    VStack(spacing: 16) {

                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }

                    // MARK: - Error Message

                    if !errorMessage.isEmpty {

                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.spendWiseDanger)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }

                    // MARK: - Sign In Button

                    Button {

                        Task {
                            await loginUser()
                        }

                    } label: {

                        if isLoading {

                            ProgressView()
                                .tint(.white)

                        } else {

                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        isLoading
                        ? Color.spendWiseSecondaryText
                        : Color.spendWiseTeal
                    )
                    .foregroundStyle(.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
                    .disabled(isLoading)

                    // MARK: - Create Account

                    Button {

                        showRegister = true

                    } label: {

                        HStack(spacing: 4) {

                            Text("Don't have an account?")
                                .foregroundStyle(
                                    Color.spendWiseSecondaryText
                                )

                            Text("Create Account")
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    Color.spendWiseTeal
                                )
                        }
                        .font(.footnote)
                    }
                    .disabled(isLoading)
                }
                .padding(24)
            }
            .background(Color.spendWiseBackground)
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showRegister) {

                RegisterView()
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - Login

    private func loginUser() async {

        errorMessage = ""

        let trimmedEmail = email
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        // Validate email

        guard !trimmedEmail.isEmpty else {

            errorMessage = "Please enter your email address."
            return
        }

        // Validate password

        guard !password.isEmpty else {

            errorMessage = "Please enter your password."
            return
        }

        isLoading = true

        do {

            try await firebaseService.login(
                email: trimmedEmail,
                password: password
            )

        } catch {

            errorMessage = firebaseErrorMessage(error)
        }

        isLoading = false
    }

    // MARK: - Firebase Error Messages

    private func firebaseErrorMessage(
        _ error: Error
    ) -> String {

        guard let authError = error as NSError? else {

            return "Something went wrong. Please try again."
        }

        switch authError.code {

        case AuthErrorCode.invalidEmail.rawValue:

            return "Please enter a valid email address."

        case AuthErrorCode.wrongPassword.rawValue:

            return "Incorrect email or password."

        case AuthErrorCode.userNotFound.rawValue:

            return "No account was found with this email."

        case AuthErrorCode.networkError.rawValue:

            return "Network error. Please check your internet connection."

        case AuthErrorCode.userDisabled.rawValue:

            return "This account has been disabled."

        default:

            return "Unable to sign in. Please check your details and try again."
        }
    }
}

#Preview {

    LoginView()
        .environmentObject(AppState())
}

#Preview {
    LoginView()
}
