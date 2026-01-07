import XCTest
@testable import Catchup

final class StreakDateTests: XCTestCase {

    func testDayKeyAndParseRoundTrip_UTC() {
        let tz = "UTC"
        var comps = DateComponents()
        comps.year = 2025
        comps.month = 12
        comps.day = 1
        comps.hour = 23
        comps.minute = 59
        comps.timeZone = TimeZone(identifier: tz)
        let date = Calendar(identifier: .gregorian).date(from: comps)!
        let key = StreakDate.dayKey(for: date, tzId: tz)
        XCTAssertEqual(key, "2025-12-01")
        let parsed = StreakDate.parseDayKey(key, tzId: tz)
        XCTAssertNotNil(parsed)
        let key2 = StreakDate.dayKey(for: parsed!, tzId: tz)
        XCTAssertEqual(key2, key)
    }

    func testDayKey_TimezoneBoundaryTokyo() {
        let tz = "Asia/Tokyo"
        var comps = DateComponents()
        comps.year = 2025
        comps.month = 1
        comps.day = 2
        comps.hour = 0
        comps.minute = 30
        comps.timeZone = TimeZone(identifier: tz)
        let date = Calendar(identifier: .gregorian).date(from: comps)!
        let key = StreakDate.dayKey(for: date, tzId: tz)
        XCTAssertEqual(key, "2025-01-02")
    }

    func testUpdatedStreak_firstAnswerSetsTo1() {
        let tz = "UTC"
        let today = StreakDate.dayKey(tzId: tz)
        let (s, last) = StreakDate.updatedStreak(oldStreak: 0, lastDateKey: nil, todayKey: today, tzId: tz)
        XCTAssertEqual(s, 1)
        XCTAssertEqual(last, today)
    }

    func testUpdatedStreak_sameDayIdempotent() {
        let tz = "UTC"
        let today = StreakDate.dayKey(tzId: tz)
        let (s, last) = StreakDate.updatedStreak(oldStreak: 3, lastDateKey: today, todayKey: today, tzId: tz)
        XCTAssertEqual(s, 3)
        XCTAssertEqual(last, today)
    }

    func testUpdatedStreak_consecutiveDayIncrements() {
        let tz = "UTC"
        let cal = Calendar(identifier: .gregorian)
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayKey = StreakDate.dayKey(for: yesterday, tzId: tz)
        let todayKey = StreakDate.dayKey(tzId: tz)
        let (s, last) = StreakDate.updatedStreak(oldStreak: 5, lastDateKey: yesterdayKey, todayKey: todayKey, tzId: tz)
        XCTAssertEqual(s, 6)
        XCTAssertEqual(last, todayKey)
    }

    func testUpdatedStreak_missedDaysResets() {
        let tz = "UTC"
        let cal = Calendar(identifier: .gregorian)
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: Date())!
        let twoDaysKey = StreakDate.dayKey(for: twoDaysAgo, tzId: tz)
        let todayKey = StreakDate.dayKey(tzId: tz)
        let (s, last) = StreakDate.updatedStreak(oldStreak: 10, lastDateKey: twoDaysKey, todayKey: todayKey, tzId: tz)
        XCTAssertEqual(s, 1)
        XCTAssertEqual(last, todayKey)
    }
}

