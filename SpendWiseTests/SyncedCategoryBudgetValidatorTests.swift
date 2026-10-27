//
//  SyncedCategoryBudgetValidatorTests.swift
//  SpendWiseTests
//
//  Created by Student4 on 2026-10-27.
//


import XCTest
@testable import SpendWise

final class SyncedCategoryBudgetValidatorTests: XCTestCase {

    private let validUserID = "user-123"

    private func validate(
        budgetID: String? = "budget-123",
        userID: String? = "user-123",
        category: String? = "Food",
        limit: Double = 300,
        month: Int = 6
    ) -> Bool {
        SyncedCategoryBudgetValidator.validate(
            budgetID: budgetID,
            userID: userID,
            expectedUserID: validUserID,
            category: category,
            limit: limit,
            month: month
        )
    }

    func testValidCategoryBudgetReturnsTrue() {
        XCTAssertTrue(validate())
    }

    func testMissingBudgetIDReturnsFalse() {
        XCTAssertFalse(validate(budgetID: nil))
    }

    func testEmptyBudgetIDReturnsFalse() {
        XCTAssertFalse(validate(budgetID: ""))
    }

    func testMissingUserIDReturnsFalse() {
        XCTAssertFalse(validate(userID: nil))
    }

    func testDifferentUserIDReturnsFalse() {
        XCTAssertFalse(validate(userID: "another-user"))
    }

    func testMissingCategoryReturnsFalse() {
        XCTAssertFalse(validate(category: nil))
    }

    func testEmptyCategoryReturnsFalse() {
        XCTAssertFalse(validate(category: ""))
    }

    func testZeroLimitReturnsFalse() {
        XCTAssertFalse(validate(limit: 0))
    }

    func testNegativeLimitReturnsFalse() {
        XCTAssertFalse(validate(limit: -100))
    }

    func testInfiniteLimitReturnsFalse() {
        XCTAssertFalse(validate(limit: .infinity))
    }

    func testNaNLimitReturnsFalse() {
        XCTAssertFalse(validate(limit: .nan))
    }

    func testPositiveLimitReturnsTrue() {
        XCTAssertTrue(validate(limit: 0.01))
    }

    func testMonthBelowValidRangeReturnsFalse() {
        XCTAssertFalse(validate(month: 0))
    }

    func testMonthAboveValidRangeReturnsFalse() {
        XCTAssertFalse(validate(month: 13))
    }

    func testFirstMonthReturnsTrue() {
        XCTAssertTrue(validate(month: 1))
    }

    func testLastMonthReturnsTrue() {
        XCTAssertTrue(validate(month: 12))
    }
}

