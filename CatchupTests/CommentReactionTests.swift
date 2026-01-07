//
//  CommentReactionTests.swift
//  Catchup
//
//  Created by Eric Lin on 12/3/25.
//


import XCTest
import FirebaseFirestore
@testable import Catchup

final class CommentReactionTests: XCTestCase {

    func testCommentDict() {
        let now = Date()
        let c = Comment(id: "c1", authorUid: "u1", authorName: "Nick", text: "Hi", createdAt: now)
        let d = c.dict

        XCTAssertEqual(d["authorUid"] as? String, "u1")
        XCTAssertEqual(d["authorName"] as? String, "Nick")
        XCTAssertEqual(d["text"] as? String, "Hi")
        XCTAssertNotNil(d["createdAt"] as? Timestamp)
    }

    func testReactionDict() {
        let now = Date()
        let r = Reaction(id: "r1", emoji: "👍", userUid: "u2", createdAt: now)
        let d = r.dict

        XCTAssertEqual(d["emoji"] as? String, "👍")
        XCTAssertEqual(d["userUid"] as? String, "u2")
        XCTAssertNotNil(d["createdAt"] as? Timestamp)
    }
}

