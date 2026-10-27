//
//  SyncedCategoryBudgetValidator.swift
//  SpendWise
//
//  Created by Student4 on 2026-10-27.
//

import Foundation

struct SyncedCategoryBudgetValidator {

    static func validate(
        budgetID: String?,
        userID: String?,
        expectedUserID: String,
        category: String?,
        limit: Double,
        month: Int
    ) -> Bool {

        guard
            let budgetID = budgetID,
            !budgetID.isEmpty,
            let userID = userID,
            userID == expectedUserID,
            let category = category,
            !category.isEmpty
        else {
            return false
        }

        guard
            limit.isFinite,
            limit > 0,
            (1...12).contains(month)
        else {
            return false
        }

        return true
    }
}

