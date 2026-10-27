//
//  FirebaseAuthErrorMapperTests.swift
//  SpendWiseTests
//
//  Created by Student4 on 2026-10-27.
//

import XCTest
import FirebaseAuth
@testable import SpendWise

final class FirebaseAuthErrorMapperTests: XCTestCase {

    func testLoginMapsInvalidEmailError() {
        let error = NSError(
            domain: AuthErrorDomain,
            code: AuthErrorCode.invalidEmail.rawValue
        )

        XCTAssertEqual(
            FirebaseAuthErrorMapper.loginMessage(for: error),
            "Please enter a valid email address."
        )
    }

    func testLoginMapsWrongPasswordError() {
        let error = NSError(
            domain: AuthErrorDomain,
            code: AuthErrorCode.wrongPassword.rawValue
        )

        XCTAssertEqual(
            FirebaseAuthErrorMapper.loginMessage(for: error),
            "Incorrect email or password."
        )
    }

    func testLoginMapsNetworkError() {
        let error = NSError(
            domain: AuthErrorDomain,
            code: AuthErrorCode.networkError.rawValue
        )

        XCTAssertEqual(
            FirebaseAuthErrorMapper.loginMessage(for: error),
            "Network error. Please check your internet connection."
        )
    }

    func testRegistrationMapsEmailAlreadyInUseError() {
        let error = NSError(
            domain: AuthErrorDomain,
            code: AuthErrorCode.emailAlreadyInUse.rawValue
        )

        XCTAssertEqual(
            FirebaseAuthErrorMapper.registrationMessage(for: error),
            "This email is already registered."
        )
    }

    func testRegistrationMapsWeakPasswordError() {
        let error = NSError(
            domain: AuthErrorDomain,
            code: AuthErrorCode.weakPassword.rawValue
        )

        XCTAssertEqual(
            FirebaseAuthErrorMapper.registrationMessage(for: error),
            "Password is too weak. Please use a stronger password."
        )
    }

    func testRegistrationMapsNetworkError() {
        let error = NSError(
            domain: AuthErrorDomain,
            code: AuthErrorCode.networkError.rawValue
        )

        XCTAssertEqual(
            FirebaseAuthErrorMapper.registrationMessage(for: error),
            "Network error. Please check your internet connection."
        )
    }

}
