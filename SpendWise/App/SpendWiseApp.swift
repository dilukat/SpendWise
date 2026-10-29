//
//  SpendWiseApp.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI
import FirebaseCore

@main
struct SpendWiseApp: App {

    @StateObject private var appState = AppState()

    @AppStorage("faceIDEnabled")
    private var faceIDEnabled = false

    @State private var isAppUnlocked = false
    @State private var hasEnteredBackground = false

    init() {
        FirebaseApp.configure()

        // Start monitoring network connectivity for expense sync.
        _ = ExpenseSyncMonitor.shared
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if faceIDEnabled && !isAppUnlocked {
                    AppLockView {
                        isAppUnlocked = true
                    }
                } else {
                    RootView()
                        .environmentObject(appState)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background:
                    hasEnteredBackground = true
                    print("SpendWise entered background.")

                case .active:
                    if hasEnteredBackground && faceIDEnabled {
                        isAppUnlocked = false
                        print("SpendWise locked after returning.")
                    }
                    hasEnteredBackground = false

                default:
                    break
                }
            }
            .onChange(of: faceIDEnabled) { _, isEnabled in
                if isEnabled {
                    isAppUnlocked = false
                } else {
                    isAppUnlocked = true
                }
            }
            .preferredColorScheme(.light)
        }
    }

    @Environment(\.scenePhase) private var scenePhase
}

