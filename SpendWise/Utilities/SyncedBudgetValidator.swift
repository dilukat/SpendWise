//
//  SyncedBudgetValidator.swift
//  SpendWise
//
//  Created by Student4 on 2026-10-27.
//

import Foundation

struct SyncedBudgetValidator {

    static func validate(
        budgetID: String?,
        userID: String?,
        expectedUserID: String,
        month: Int,
        year: Int,
        amount: Double
    ) -> Bool {

        guard
            let budgetID = budgetID,
            !budgetID.isEmpty,
            let userID = userID,
            userID == expectedUserID
        else {
            return false
        }

        guard
            (1...12).contains(month),
            (1...9999).contains(year),
            amount.isFinite,
            amount > 0
        else {
            return false
        }

        return true
    }
}
