//
//  BudgetValidator.swift
//  SpendWise
//
//  Created by Student4 on 2026-10-27.
//

import Foundation

struct BudgetValidator {

    static func validateMonthlyBudget(_ value: String) -> String? {
        let trimmedValue = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let amount = Double(trimmedValue),
              amount.isFinite,
              amount > 0 else {
            return "Please enter a valid budget amount greater than zero."
        }

        return nil
    }

    static func validateCategoryBudget(_ value: String) -> String? {
        let trimmedValue = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let amount = Double(trimmedValue),
              amount.isFinite,
              amount > 0 else {
            return "Enter a valid category limit greater than zero."
        }

        return nil
    }
}

