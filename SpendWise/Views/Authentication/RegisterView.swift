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

                VStack(spacing: 24) {

                    // MARK: - Header

                    VStack(spacing: 8) {

                        Text("SpendWise")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.spendWiseTeal)

                        Text("Create your account")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Start managing your personal expenses")
                            .font(.subheadline)
                            .foregroundStyle(Color.spendWiseSecondaryText)
                    }
                    .padding(.top, 20)

                    // MARK: - Form

                    VStack(spacing: 16) {

                        TextField("Full Name", text: $fullName)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)

                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                    }

                    // MARK: - Error Message

                    if !errorMessage.isEmpty {

                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.spendWiseDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // MARK: - Terms

                    HStack(alignment: .top, spacing: 8) {

                        Image(systemName: "checkmark.square")
                            .foregroundStyle(Color.spendWiseTeal)

                        Text("I agree to the Terms & Privacy Policy")
                            .font(.footnote)
                            .foregroundStyle(Color.spendWiseSecondaryText)

                        Spacer()
                    }

                    // MARK: - Create Account

                    Button {

                        Task {
                            await registerUser()
                        }

                    } label: {

                        if isLoading {

                            ProgressView()
                                .tint(.white)

                        } else {

                            Text("Create Account")
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

                    // MARK: - Login

                    Button {

                        dismiss()

                    } label: {

                        HStack(spacing: 4) {

                            Text("Already have an account?")
                                .foregroundStyle(Color.spendWiseSecondaryText)

                            Text("Sign In")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.spendWiseTeal)
                        }
                        .font(.footnote)
                    }
                    .disabled(isLoading)
                }
                .padding(24)
            }
            .background(Color.spendWiseBackground)
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Register User

    private func registerUser() async {

        errorMessage = ""

        let trimmedName = fullName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // Validate full name

        guard !trimmedName.isEmpty else {

            errorMessage = "Please enter your full name."
            return
        }

        // Validate email

        guard !trimmedEmail.isEmpty else {

            errorMessage = "Please enter your email address."
            return
        }

        // Validate password

        guard !password.isEmpty else {

            errorMessage = "Please enter a password."
            return
        }

        // Validate password confirmation

        guard password == confirmPassword else {

            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true

        do {

            try await firebaseService.register(
                fullName: trimmedName,
                email: trimmedEmail,
                password: password
            )

            // Firebase automatically signs the user in
            // after successful registration.

            appState.isAuthenticated = true

        } catch {

            errorMessage = firebaseErrorMessage(error)

        }

        isLoading = false
    }

    // MARK: - Firebase Error Handling

    private func firebaseErrorMessage(_ error: Error) -> String {

        guard let authError = error as NSError? else {
            return "Something went wrong. Please try again."
        }

        switch authError.code {

        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "This email is already registered."

        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address."

        case AuthErrorCode.weakPassword.rawValue:
            return "Password is too weak. Please use a stronger password."

        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your internet connection."

        default:
            return "Unable to create your account. Please try again."
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AppState())
}

