//
//  AuthControllerTests.swift
//  Catchup
//
//  Created by Eric Lin on 12/3/25.
//


import XCTest
@testable import Catchup

final class AuthControllerTests: XCTestCase {

    actor MockUsersRepo: UsersRepositoryType {
        private var _usernameExistsResult: Bool = false

        func setUsernameExistsResult(_ value: Bool) {
            _usernameExistsResult = value
        }

        func get(uid: String) async throws -> User {
            fatalError("Not used in these tests")
        }

        func createUserDoc(_ user: User) async throws {
            // no-op
        }

        func usernameExists(_ username: String) async throws -> Bool {
            return _usernameExistsResult
        }
    }

    @MainActor
    func testSignUp_usernameTaken_setsErrorAndSkipsAuth() async throws {
        let mock = MockUsersRepo()
        await mock.setUsernameExistsResult(true)

        let sut = AuthController(usersRepo: mock)
        await sut.signUp(displayName: "Nick", username: "nick", email: "e@example.com", password: "pw")

        XCTAssertEqual(sut.errorMessage, "Username already taken.")
        XCTAssertFalse(sut.isBusy)
    }

    @MainActor
    func testSignUp_missingFields_setsErrorImmediately() async {
        let sut = AuthController(usersRepo: MockUsersRepo())
        await sut.signUp(displayName: "", username: "nick", email: "e@example.com", password: "pw")
        XCTAssertEqual(sut.errorMessage, "Fill all fields.")
    }

    struct ThrowingUsersRepo: UsersRepositoryType {
        struct Dummy: Error {}
        func get(uid: String) async throws -> User { throw Dummy() }
        func createUserDoc(_ user: User) async throws { throw Dummy() }
        func usernameExists(_ username: String) async throws -> Bool { throw Dummy() }
    }

    @MainActor
    func testSignUp_repoError_setsErrorMessage() async {
        let sut = AuthController(usersRepo: ThrowingUsersRepo())
        await sut.signUp(displayName: "Nick", username: "nick", email: "e@example.com", password: "pw")
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isBusy)
    }
}

