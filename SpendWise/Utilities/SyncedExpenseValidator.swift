//
//  SyncedExpenseValidator.swift
//  SpendWise
//
//  Created by Student4 on 2026-10-27.
//

import Foundation

struct SyncedExpenseValidator {

    static func validate(
        expenseID: String?,
        userID: String?,
        expectedUserID: String,
        amount: Double
    ) -> Bool {

        guard
            let expenseID = expenseID,
            !expenseID.isEmpty,
            let userID = userID,
            userID == expectedUserID
        else {
            return false
        }

        guard amount.isFinite, amount > 0 else {
            return false
        }

        return true
    }
}

