//
//  BudgetView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI

struct BudgetView: View {

    var body: some View {

        NavigationStack {

            VStack {

                Text("Budget")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding()
            .background(Color.spendWiseBackground)
            .navigationTitle("Budget")
        }
    }
}

#Preview {
    BudgetView()
}
