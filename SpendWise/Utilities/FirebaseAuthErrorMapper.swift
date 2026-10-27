//
//  FirebaseAuthErrorMapper.swift
//  SpendWise
//
//  Created by Student4 on 2026-10-27.
//


import Foundation
import FirebaseAuth

enum FirebaseAuthErrorMapper {

    static func loginMessage(for error: Error) -> String {
        let authError = error as NSError

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

    static func registrationMessage(for error: Error) -> String {
        let authError = error as NSError

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

