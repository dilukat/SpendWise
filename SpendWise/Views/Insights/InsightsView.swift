//
//  InsightsView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-01.
//

import SwiftUI

struct InsightsView: View {

    var body: some View {

        NavigationStack {

            VStack {

                Text("Insights")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding()
            .background(Color.spendWiseBackground)
            .navigationTitle("Insights")
        }
    }
}

#Preview {
    InsightsView()
}
