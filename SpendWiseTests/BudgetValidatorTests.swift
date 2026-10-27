//
//  BudgetValidatorTests.swift
//  SpendWiseTests
//
//  Created by Student4 on 2026-10-27.
//

import XCTest
@testable import SpendWise

final class BudgetValidatorTests: XCTestCase {

    func testMonthlyBudgetRejectsEmptyInput() {
        XCTAssertNotNil(
            BudgetValidator.validateMonthlyBudget("")
        )
    }

    func testMonthlyBudgetRejectsInvalidInput() {
        XCTAssertNotNil(
            BudgetValidator.validateMonthlyBudget("abc")
        )
    }

    func testMonthlyBudgetRejectsZero() {
        XCTAssertNotNil(
            BudgetValidator.validateMonthlyBudget("0")
        )
    }

    func testMonthlyBudgetRejectsNegativeAmount() {
        XCTAssertNotNil(
            BudgetValidator.validateMonthlyBudget("-100")
        )
    }

    func testMonthlyBudgetAcceptsPositiveAmount() {
        XCTAssertNil(
            BudgetValidator.validateMonthlyBudget("1000")
        )
    }

    func testMonthlyBudgetAcceptsWhitespaceAroundAmount() {
        XCTAssertNil(
            BudgetValidator.validateMonthlyBudget(" 1000 ")
        )
    }

    func testCategoryBudgetRejectsEmptyInput() {
        XCTAssertNotNil(
            BudgetValidator.validateCategoryBudget("")
        )
    }

    func testCategoryBudgetRejectsInvalidInput() {
        XCTAssertNotNil(
            BudgetValidator.validateCategoryBudget("abc")
        )
    }

    func testCategoryBudgetRejectsZero() {
        XCTAssertNotNil(
            BudgetValidator.validateCategoryBudget("0")
        )
    }

    func testCategoryBudgetRejectsNegativeAmount() {
        XCTAssertNotNil(
            BudgetValidator.validateCategoryBudget("-100")
        )
    }

    func testCategoryBudgetAcceptsPositiveAmount() {
        XCTAssertNil(
            BudgetValidator.validateCategoryBudget("1000")
        )
    }

    func testCategoryBudgetAcceptsWhitespaceAroundAmount() {
        XCTAssertNil(
            BudgetValidator.validateCategoryBudget(" 1000 ")
        )
    }
}

