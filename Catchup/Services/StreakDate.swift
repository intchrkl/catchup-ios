//
//  StreakDate.swift
//  Catchup
//
//  Created by Nick Jitjang on 11/19/25.
//

import Foundation

enum StreakDate {
    /// Day key like "2025-10-30" in the given timezone
    static func dayKey(for date: Date = Date(), tzId: String) -> String {
        let tz = TimeZone(identifier: tzId) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let normalized = cal.date(from: comps) ?? date

        let df = DateFormatter()
        df.calendar = cal
        df.timeZone = tz
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: normalized)
    }

    static func parseDayKey(_ key: String, tzId: String) -> Date? {
        let tz = TimeZone(identifier: tzId) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        let df = DateFormatter()
        df.calendar = cal
        df.timeZone = tz
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: key)
    }

    /// Returns (newStreak, newLastDateKey). Idempotent for multiple answers in same day.
    static func updatedStreak(oldStreak: Int,
                              lastDateKey: String?,
                              todayKey: String,
                              tzId: String) -> (Int, String) {

        // Same day → don’t bump streak again
        if lastDateKey == todayKey {
            return (oldStreak, lastDateKey ?? todayKey)
        }

        guard let lastKey = lastDateKey,
              let last = parseDayKey(lastKey, tzId: tzId),
              let today = parseDayKey(todayKey, tzId: tzId)
        else {
            // first ever streak
            return (max(oldStreak, 1), todayKey)
        }

        let tz = TimeZone(identifier: tzId) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let diff = cal.dateComponents([.day], from: last, to: today).day ?? 0

        if diff == 1 {
            // consecutive day → streak continues
            return (oldStreak + 1, todayKey)
        } else {
            // missed at least one day → reset to 1 for today
            return (1, todayKey)
        }
    }
}
