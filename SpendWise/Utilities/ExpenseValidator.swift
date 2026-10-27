//
//  ExpenseValidator.swift
//  SpendWise
//
//  Created by Student4 on 2026-10-27.
//

import Foundation

enum ExpenseValidator {

    static func validateAmount(_ amount: String) -> String? {
        guard let expenseAmount = Double(amount),
              expenseAmount.isFinite,
              expenseAmount > 0 else {
            return "Please enter a valid amount."
        }

        return nil
    }
}
