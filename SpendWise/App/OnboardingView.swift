//
//  OnboardingView.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-26.
//

import SwiftUI

struct OnboardingView: View {

    @State private var currentPage = 0

    let onComplete: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to SpendWise",
            description: "Take control of your money and make smarter financial decisions.",
            symbol: "chart.pie.fill",
            color: .spendWiseTeal
        ),
        OnboardingPage(
            title: "Track Your Expenses",
            description: "Record your daily spending and scan receipts to save time.",
            symbol: "receipt.fill",
            color: .spendWiseTeal
        ),
        OnboardingPage(
            title: "Plan Your Budget",
            description: "Set monthly budgets, monitor your spending, and understand your habits.",
            symbol: "chart.bar.fill",
            color: .spendWiseTeal
        ),
        OnboardingPage(
            title: "Understand Your Money",
            description: "Explore spending insights and make better financial choices.",
            symbol: "lightbulb.fill",
            color: .spendWiseTeal
        )
    ]

    var body: some View {
        VStack(spacing: 24) {

            HStack {
                Text("SpendWise")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button("Skip") {
                    onComplete()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(
                            currentPage == index
                            ? Color.spendWiseTeal
                            : Color.gray.opacity(0.3)
                        )
                        .frame(
                            width: currentPage == index ? 24 : 8,
                            height: 8
                        )
                }
            }

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    onComplete()
                }
            } label: {
                Text(
                    currentPage == pages.count - 1
                    ? "Get Started"
                    : "Continue"
                )
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.spendWiseTeal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .padding(.top)
        .background(Color(.systemBackground))
    }

    private func onboardingPage(
        _ page: OnboardingPage
    ) -> some View {
        VStack(spacing: 28) {

            Spacer()

            Image(systemName: page.symbol)
                .font(.system(size: 90))
                .foregroundStyle(page.color)
                .frame(height: 150)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 16)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

private struct OnboardingPage {
    let title: String
    let description: String
    let symbol: String
    let color: Color
}
