//
//  QuestionCategoryTests.swift
//  Catchup
//
//  Created by Eric Lin on 12/3/25.
//


import XCTest
@testable import Catchup

final class QuestionCategoryTests: XCTestCase {

    func testIdEqualsRawValue() {
        for c in QuestionCategory.allCases {
            XCTAssertEqual(c.id, c.rawValue)
        }
    }

    func testSystemPromptNonEmpty() {
        for c in QuestionCategory.allCases {
            XCTAssertFalse(c.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

