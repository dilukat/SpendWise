//
//  MainTabView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI

struct MainTabView: View {

    var body: some View {

        TabView {

            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }

            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "wallet.pass.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.spendWiseTeal)
    }
}

#Preview {
    MainTabView()
}
