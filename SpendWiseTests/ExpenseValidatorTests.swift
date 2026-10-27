//
//  ExpenseValidatorTests.swift
//  SpendWiseTests
//
//  Created by Student4 on 2026-10-27.
//


import XCTest
@testable import SpendWise

final class ExpenseValidatorTests: XCTestCase {

    func testExpenseAmountRejectsEmptyInput() {
        XCTAssertEqual(
            ExpenseValidator.validateAmount(""),
            "Please enter a valid amount."
        )
    }

    func testExpenseAmountRejectsNonNumericInput() {
        XCTAssertEqual(
            ExpenseValidator.validateAmount("abc"),
            "Please enter a valid amount."
        )
    }

    func testExpenseAmountRejectsZero() {
        XCTAssertEqual(
            ExpenseValidator.validateAmount("0"),
            "Please enter a valid amount."
        )
    }

    func testExpenseAmountAcceptsPositiveNumber() {
        XCTAssertNil(
            ExpenseValidator.validateAmount("1250.50")
        )
    }
}

