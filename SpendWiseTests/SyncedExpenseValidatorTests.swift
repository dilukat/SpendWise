//
//  SyncedExpenseValidatorTests.swift
//  SpendWiseTests
//
//  Created by Student4 on 2026-10-27.
//

import XCTest
@testable import SpendWise

final class SyncedExpenseValidatorTests: XCTestCase {

    private let validUserID = "user-123"

    private func validate(
        expenseID: String? = "expense-123",
        userID: String? = "user-123",
        amount: Double = 50
    ) -> Bool {
        SyncedExpenseValidator.validate(
            expenseID: expenseID,
            userID: userID,
            expectedUserID: validUserID,
            amount: amount
        )
    }

    func testValidExpenseReturnsTrue() {
        XCTAssertTrue(validate())
    }

    func testMissingExpenseIDReturnsFalse() {
        XCTAssertFalse(validate(expenseID: nil))
    }

    func testEmptyExpenseIDReturnsFalse() {
        XCTAssertFalse(validate(expenseID: ""))
    }

    func testMissingUserIDReturnsFalse() {
        XCTAssertFalse(validate(userID: nil))
    }

    func testDifferentUserIDReturnsFalse() {
        XCTAssertFalse(validate(userID: "another-user"))
    }

    func testZeroAmountReturnsFalse() {
        XCTAssertFalse(validate(amount: 0))
    }

    func testNegativeAmountReturnsFalse() {
        XCTAssertFalse(validate(amount: -10))
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

