//
//  HomeView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI

struct HomeView: View {

    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                Text("Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("SpendWise Dashboard")
                    .foregroundStyle(Color.spendWiseSecondaryText)

                Spacer()
            }
            .padding()
            .background(Color.spendWiseBackground)
            .navigationTitle("SpendWise")
        }
    }
}
#Preview {
    HomeView()
}
