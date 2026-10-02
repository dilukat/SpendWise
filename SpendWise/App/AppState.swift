//
//  AppState.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI
import FirebaseAuth
internal import Combine

@MainActor
final class AppState: ObservableObject {

    @Published var isAuthenticated = false

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {

        isAuthenticated = Auth.auth().currentUser != nil

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in

            Task { @MainActor in

                self?.isAuthenticated = user != nil
            }
        }
    }

    deinit {

        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }
}
