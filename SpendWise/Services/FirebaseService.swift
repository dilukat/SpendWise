//
//  FirebaseService.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import Foundation
import FirebaseAuth

@MainActor
final class FirebaseService {

    static let shared = FirebaseService()

    private init() {}

    // Register

    func register(
        fullName: String,
        email: String,
        password: String
    ) async throws {

        let result = try await Auth.auth().createUser(
            withEmail: email,
            password: password
        )

        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = fullName

        try await changeRequest.commitChanges()
    }

    // Login

    func login(
        email: String,
        password: String
    ) async throws {

        try await Auth.auth().signIn(
            withEmail: email,
            password: password
        )
    }

    // Logout

    func logout() throws {

        try Auth.auth().signOut()
    }

    // Current User

    var currentUser: FirebaseAuth.User? {

        Auth.auth().currentUser
    }

    // Authentication State

    var isAuthenticated: Bool {

        Auth.auth().currentUser != nil
    }
}
