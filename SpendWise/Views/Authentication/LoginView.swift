//
//  LoginView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI

struct LoginView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {

        VStack(spacing: 24) {

            Spacer()

            Text("SpendWise")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(Color.spendWiseTeal)

            Text("Smart Personal Expense Manager")
                .foregroundStyle(Color.spendWiseSecondaryText)

            Button("Continue") {
                appState.isAuthenticated = true
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.spendWiseTeal)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()
        }
        .padding(24)
        .background(Color.spendWiseBackground)
    }
}

#Preview {
    LoginView()
}
