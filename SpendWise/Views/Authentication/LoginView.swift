//
//  LoginView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI

struct LoginView: View {

    @EnvironmentObject var appState: AppState

    @State private var showRegister = false

    var body: some View {

        NavigationStack {

            VStack(spacing: 24) {

                Spacer()

                // MARK: - Logo / Title

                VStack(spacing: 8) {

                    Text("SpendWise")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.spendWiseTeal)

                    Text("Smart Personal Expense Manager")
                        .foregroundStyle(Color.spendWiseSecondaryText)
                }

                // Temporary login area

                Button("Continue") {
                    appState.isAuthenticated = true
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.spendWiseTeal)
                .foregroundStyle(.white)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )

                // Register

                Button {
                    showRegister = true
                } label: {

                    HStack(spacing: 4) {

                        Text("Don't have an account?")
                            .foregroundStyle(Color.spendWiseSecondaryText)

                        Text("Create Account")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.spendWiseTeal)
                    }
                    .font(.footnote)
                }

                Spacer()
            }
            .padding(24)
            .background(Color.spendWiseBackground)
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}

#Preview {
    LoginView()
}
