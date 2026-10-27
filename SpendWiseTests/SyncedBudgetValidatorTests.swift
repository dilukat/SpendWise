//
//  SyncedBudgetValidatorTests.swift
//  SpendWiseTests
//
//  Created by Student4 on 2026-10-27.
//

import XCTest
@testable import SpendWise

final class SyncedBudgetValidatorTests: XCTestCase {

    private let validBudgetID = "budget-123"
    private let validUserID = "user-123"

    private func validate(
        budgetID: String? = "budget-123",
        userID: String? = "user-123",
        month: Int = 6,
        year: Int = 2026,
        amount: Double = 1000
    ) -> Bool {
        SyncedBudgetValidator.validate(
            budgetID: budgetID,
            userID: userID,
            expectedUserID: validUserID,
            month: month,
            year: year,
            amount: amount
        )
    }

    func testValidBudgetReturnsTrue() {
        XCTAssertTrue(validate())
    }

    func testMissingBudgetIDReturnsFalse() {
        XCTAssertFalse(validate(budgetID: nil))
    }

    func testEmptyBudgetIDReturnsFalse() {
        XCTAssertFalse(validate(budgetID: ""))
    }

    func testDifferentUserIDReturnsFalse() {
        XCTAssertFalse(validate(userID: "another-user"))
    }

    func testMissingUserIDReturnsFalse() {
        XCTAssertFalse(validate(userID: nil))
    }

    func testMonthBelowValidRangeReturnsFalse() {
        XCTAssertFalse(validate(month: 0))
    }

    func testMonthAboveValidRangeReturnsFalse() {
        XCTAssertFalse(validate(month: 13))
    }

    func testMinimumValidMonthReturnsTrue() {
        XCTAssertTrue(validate(month: 1))
    }

    func testMaximumValidMonthReturnsTrue() {
        XCTAssertTrue(validate(month: 12))
    }

    func testYearBelowValidRangeReturnsFalse() {
        XCTAssertFalse(validate(year: 0))
    }

    func testYearAboveValidRangeReturnsFalse() {
        XCTAssertFalse(validate(year: 10000))
    }

    func testMinimumValidYearReturnsTrue() {
        XCTAssertTrue(validate(year: 1))
    }

    func testMaximumValidYearReturnsTrue() {
        XCTAssertTrue(validate(year: 9999))
    }

    func testZeroAmountReturnsFalse() {
        XCTAssertFalse(validate(amount: 0))
    }

    func testNegativeAmountReturnsFalse() {
        XCTAssertFalse(validate(amount: -100))
    }

    func testInfiniteAmountReturnsFalse() {
        XCTAssertFalse(validate(amount: .infinity))
    }

    func testNaNAmountReturnsFalse() {
        XCTAssertFalse(validate(amount: .nan))
    }

    func testPositiveAmountReturnsTrue() {
        XCTAssertTrue(validate(amount: 0.01))
    }
}

