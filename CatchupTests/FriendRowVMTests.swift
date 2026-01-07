//
//  FriendRowVMTests.swift
//  Catchup
//
//  Created by Eric Lin on 12/3/25.
//


import XCTest
@testable import Catchup

final class FriendRowVMTests: XCTestCase {
    func testBasics() {
        let now = Date()
        let vm = FriendRowVM(uid: "f1", displayName: "Sam", username: "sam", photoURL: nil, since: now, streaks: 7)
        XCTAssertEqual(vm.id, "f1")
        XCTAssertEqual(vm.displayName, "Sam")
        XCTAssertEqual(vm.username, "sam")
        XCTAssertNil(vm.photoURL)
        XCTAssertEqual(vm.streaks, 7)
        XCTAssertEqual(vm.since, now)
    }
}

