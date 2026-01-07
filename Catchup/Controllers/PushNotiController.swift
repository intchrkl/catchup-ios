//
//  PushNotiController.swift
//  Catchup
//
//  Created by Nick Jitjang on 11/19/25.
//

import Foundation

@MainActor
final class LocalPushCoordinator {
    static let shared = LocalPushCoordinator()
    private init() {}

    /// (Idempotent) ensure daily notifications exist
    func ensureDailySchedules(pushEnabled: Bool, inAppNotification: Bool) {
        guard pushEnabled && inAppNotification else {
            NotificationService.shared.cancelAll()
            return
        }

        // 1) 9:00 AM – repeating "New Question"
        let newQ = LocalNotification(
            id: AppNotifID.newQuestionDaily,
            title: "New Question",
            body: "Today’s question is live. Share your thoughts!",
            userInfo: ["deeplink": "/question/today"],
            trigger: dailyTrigger(hour: 9, minute: 0)  // repeats = true
        )
        NotificationService.shared.schedule(newQ)

        // 2) 9:00 PM – one-shot streak reminders for the next 7 days
        let calendar = Calendar.current
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: Date()) else { continue }

            let id = AppNotifID.streakReminder(for: day)
            let trigger = calendarTrigger(on: day, hour: 21, minute: 0)

            let streak = LocalNotification(
                id: id,
                title: "Don’t lose your streak",
                body: "Answer before midnight to keep it going!",
                userInfo: ["deeplink": "/streak"],
                trigger: trigger
            )
            NotificationService.shared.schedule(streak)
        }
    }

    /// Call after the user answers *today's* question
    func cancelTonightsStreakReminder() {
        let todayId = AppNotifID.streakReminder(for: Date())
        NotificationService.shared.cancel(ids: [todayId])
    }
}
