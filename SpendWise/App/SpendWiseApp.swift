//
//  SpendWiseApp.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI

@main
struct SpendWiseApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
