//
//  NotificationHelpersTests.swift
//  Catchup
//
//  Created by Eric Lin on 12/3/25.
//


import XCTest
import UserNotifications
@testable import Catchup

final class NotificationHelpersTests: XCTestCase {

    func testAppDateFormatting() {
        var comps = DateComponents()
        comps.year = 2024
        comps.month = 12
        comps.day = 31
        comps.hour = 10
        comps.minute = 45
        comps.second = 0
        comps.timeZone = .current

        let date = Calendar.current.date(from: comps)!
        XCTAssertEqual(AppDate.yyyyMMdd(date), "2024-12-31")
    }

    func testAppNotifID() {
        XCTAssertEqual(AppNotifID.newQuestionDaily, "new-question-daily")

        var comps = DateComponents()
        comps.year = 2025
        comps.month = 1
        comps.day = 2
        comps.timeZone = .current
        let d = Calendar.current.date(from: comps)!
        XCTAssertEqual(AppNotifID.streakReminder(for: d), "streak-2025-01-02")
    }

    func testDailyTrigger() {
        let trig = dailyTrigger(hour: 9, minute: 0, repeats: true)
        XCTAssertTrue(trig.repeats)

        let next = trig.nextTriggerDate()
        XCTAssertNotNil(next)
        if let next {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: next)
            XCTAssertEqual(comps.hour, 9)
            XCTAssertEqual(comps.minute, 0)
        }
    }

    func testTimeIntervalTrigger() {
        let trig = timeIntervalTrigger(seconds: 2, repeats: false)
        XCTAssertFalse(trig.repeats)

        guard let next = trig.nextTriggerDate() else {
            XCTFail("nextTriggerDate should not be nil")
            return
        }
        let delta = next.timeIntervalSinceNow
        XCTAssertGreaterThanOrEqual(delta, 1.0)
    }

    func testCalendarTrigger() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let trig = calendarTrigger(on: tomorrow, hour: 21, minute: 0, repeats: false)
        XCTAssertFalse(trig.repeats)

        let next = trig.nextTriggerDate()
        XCTAssertNotNil(next)
        if let next {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: next)
            XCTAssertEqual(comps.hour, 21)
            XCTAssertEqual(comps.minute, 0)
        }
    }
}

