//
//  BiometricAuthService.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-20.
//

import Foundation
import LocalAuthentication

final class BiometricAuthService {

    static let shared = BiometricAuthService()

    private init() {}

    func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            print(
                "Biometric authentication unavailable: " +
                (error?.localizedDescription ?? "Unknown error")
            )
            return false
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock SpendWise to access your expenses."
            )
        } catch {
            print("Biometric authentication failed: \(error.localizedDescription)")
            return false
        }
    }

    func isBiometricAvailable() -> Bool {
        let context = LAContext()

        return context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: nil
        )
    }

    func biometricType() -> LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: nil
        )

        return context.biometryType
    }
}

