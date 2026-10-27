//
//  ExpenseViewModelTests.swift
//  SpendWiseTests
//
//  Created by Student4 on 2026-10-27.
//

import XCTest
@testable import SpendWise

final class ExpenseViewModelTests: XCTestCase {

    @MainActor
    func testExpenseViewModelInitialization() {
        let viewModel = ExpenseViewModel(
            shouldFetchOnInit: false
        )

        XCTAssertEqual(viewModel.amount, "")
        XCTAssertEqual(viewModel.category, "Food")
        XCTAssertEqual(viewModel.errorMessage, "")
        XCTAssertFalse(viewModel.showSuccessMessage)
    }
}
  
