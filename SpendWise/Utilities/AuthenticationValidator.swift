  //
//  AuthenticationValidator.swift
//  SpendWise
//
//  Created by Student4 on 2026-10-27.
//


import Foundation

enum AuthenticationValidator {

    static func validateLogin(
        email: String,
        password: String
    ) -> String? {

        let trimmedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedEmail.isEmpty else {
            return "Please enter your email address."
        }
        
        guard isValidEmail(trimmedEmail) else {
            return "Please enter a valid email address."
        }

        guard !password.isEmpty else {
            return "Please enter your password."
        }

        return nil
    }
    
    
    static func validateRegistration(
        fullName: String,
        email: String,
        password: String,
        confirmPassword: String
    ) -> String? {

        let trimmedName = fullName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedName.isEmpty else {
            return "Please enter your full name."
        }

        guard !trimmedEmail.isEmpty else {
            return "Please enter your email address."
        }
        
        guard isValidEmail(trimmedEmail) else {
            return "Please enter a valid email address."
        }

        guard !password.isEmpty else {
            return "Please enter a password."
        }
        
        guard password.count >= 8 else {
            return "Password must be at least 8 characters."
        }

        guard password == confirmPassword else {
            return "Passwords do not match."
        }

        return nil
    }
    
    static func isValidEmail(_ email: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let emailPattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

        return trimmedEmail.range(
            of: emailPattern,
            options: .regularExpression
        ) != nil
    }

}

