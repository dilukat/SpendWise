//
//  HistoryView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI

struct HistoryView: View {

    var body: some View {

        NavigationStack {

            VStack {

                Text("Expense History")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding()
            .background(Color.spendWiseBackground)
            .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView()
}
