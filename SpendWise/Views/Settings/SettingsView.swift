//
//  SettingsView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI

struct SettingsView: View {

    var body: some View {

        NavigationStack {

            VStack {

                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding()
            .background(Color.spendWiseBackground)
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
