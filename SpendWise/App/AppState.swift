//
//  AppState.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI
internal import Combine

@MainActor
final class AppState: ObservableObject {

    @Published var isAuthenticated = false

    init() {
        // Authentication will be connected to Firebase later.
    }
}
