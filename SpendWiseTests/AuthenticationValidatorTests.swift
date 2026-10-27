//
//  AuthenticationValidatorTests.swift
//  SpendWiseTests
//
//  Created by Student4 on 2026-10-27.
//

import XCTest
@testable import SpendWise

final class AuthenticationValidatorTests: XCTestCase {

    func testLoginValidationRejectsEmptyEmail() {
        let result = AuthenticationValidator.validateLogin(
            email: "",
            password: "Password123!"
        )

        XCTAssertEqual(
            result,
            "Please enter your email address."
        )
    }

    func testLoginValidationRejectsWhitespaceOnlyEmail() {
        let result = AuthenticationValidator.validateLogin(
            email: "   ",
            password: "Password123!"
        )

        XCTAssertEqual(
            result,
            "Please enter your email address."
        )
    }

    func testLoginValidationRejectsEmptyPassword() {
        let result = AuthenticationValidator.validateLogin(
            email: "user@example.com",
            password: ""
        )

        XCTAssertEqual(
            result,
            "Please enter your password."
        )
    }

    func testLoginValidationAcceptsNonEmptyInputs() {
        let result = AuthenticationValidator.validateLogin(
            email: "user@example.com",
            password: "Password123!"
        )

        XCTAssertNil(result)
    }

    func testRegistrationRejectsEmptyName() {
        let result = AuthenticationValidator.validateRegistration(
            fullName: "   ",
            email: "user@example.com",
            password: "Password123!",
            confirmPassword: "Password123!"
        )

        XCTAssertEqual(result, "Please enter your full name.")
    }

    func testRegistrationRejectsEmptyEmail() {
        let result = AuthenticationValidator.validateRegistration(
            fullName: "Test User",
            email: " ",
            password: "Password123!",
            confirmPassword: "Password123!"
        )

        XCTAssertEqual(result, "Please enter your email address.")
    }

    func testRegistrationRejectsEmptyPassword() {
        let result = AuthenticationValidator.validateRegistration(
            fullName: "Test User",
            email: "user@example.com",
            password: "",
            confirmPassword: ""
        )

        XCTAssertEqual(result, "Please enter a password.")
    }

    func testRegistrationRejectsPasswordMismatch() {
        let result = AuthenticationValidator.validateRegistration(
            fullName: "Test User",
            email: "user@example.com",
            password: "Password123!",
            confirmPassword: "Different123!"
        )

        XCTAssertEqual(result, "Passwords do not match.")
    }

    func testRegistrationAcceptsValidInputs() {
        let result = AuthenticationValidator.validateRegistration(
            fullName: "Test User",
            email: "user@example.com",
            password: "Password123!",
            confirmPassword: "Password123!"
        )

        XCTAssertNil(result)
    }

    func testLoginRejectsInvalidEmail() {
        let result = AuthenticationValidator.validateLogin(
            email: "invalid-email",
            password: "password123"
        )

        XCTAssertEqual(
            result,
            "Please enter a valid email address."
        )
    }

    func testLoginAcceptsValidEmail() {
        let result = AuthenticationValidator.validateLogin(
            email: "user@example.com",
            password: "password123"
        )

        XCTAssertNil(result)
    }

    func testRegistrationRejectsInvalidEmail() {
        let result = AuthenticationValidator.validateRegistration(
            fullName: "Test User",
            email: "invalid-email",
            password: "password123",
            confirmPassword: "password123"
        )

        XCTAssertEqual(
            result,
            "Please enter a valid email address."
        )
    }

    func testRegistrationAcceptsValidEmail() {
        let result = AuthenticationValidator.validateRegistration(
            fullName: "Test User",
            email: "user@example.com",
            password: "password123",
            confirmPassword: "password123"
        )

        XCTAssertNil(result)
    }

    func testRegistrationRejectsPasswordShorterThanEightCharacters() {
        let result = AuthenticationValidator.validateRegistration(
            fullName: "Test User",
            email: "user@example.com",
            password: "abc123",
            confirmPassword: "abc123"
        )

        XCTAssertEqual(
            result,
            "Password must be at least 8 characters."
        )
    }

    func testRegistrationAcceptsPasswordWithEightCharacters() {
        let result = AuthenticationValidator.validateRegistration(
            fullName: "Test User",
            email: "user@example.com",
            password: "abc12345",
            confirmPassword: "abc12345"
        )

        XCTAssertNil(result)
    }


}


