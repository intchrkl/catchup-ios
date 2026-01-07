//
//  PushNotiService.swift
//  Catchup
//
//  Created by Nick Jitjang on 11/19/25.
//
import Foundation
import UserNotifications

enum AppNotifID {
    // 9am question → truly daily repeating, constant ID
    static let newQuestionDaily = "new-question-daily"
    
    // 9pm streak → one-shot per day, ID encodes date
    static func streakReminder(for date: Date = Date()) -> String {
        "streak-\(AppDate.yyyyMMdd(date))"
    }
}


enum AppDate {
    static func yyyyMMdd(_ date: Date = Date()) -> String {
        let df = DateFormatter()
        df.calendar = .init(identifier: .gregorian)
        df.locale = .init(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
}

func dailyTrigger(hour: Int, minute: Int, repeats: Bool = true) -> UNCalendarNotificationTrigger {
    var dc = DateComponents()
    dc.hour = hour; dc.minute = minute
    return UNCalendarNotificationTrigger(dateMatching: dc, repeats: repeats)
}

func timeIntervalTrigger(seconds: TimeInterval, repeats: Bool = false) -> UNTimeIntervalNotificationTrigger {
    UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: repeats)
}

func calendarTrigger(on date: Date,
                     hour: Int,
                     minute: Int,
                     repeats: Bool = false) -> UNCalendarNotificationTrigger {
    var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
    comps.hour = hour
    comps.minute = minute
    return UNCalendarNotificationTrigger(dateMatching: comps, repeats: repeats)
}


struct LocalNotification {
    let id: String
    let title: String
    let body: String
    let userInfo: [String: Any]?
    let trigger: UNNotificationTrigger
    let sound: UNNotificationSound? = .default
}

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, err in
            if let err { print("Notification permission error:", err) }
            print("Permission granted:", granted)
        }
    }

    func schedule(_ n: LocalNotification) {
        let content = UNMutableNotificationContent()
        content.title = n.title
        content.body  = n.body
        content.sound = n.sound
        if let info = n.userInfo { content.userInfo = info }
        let req = UNNotificationRequest(identifier: n.id, content: content, trigger: n.trigger)
        UNUserNotificationCenter.current().add(req) { err in
            if let err { print("Add notif error:", err) }
        }
    }

    func cancel(ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // Foreground display
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Taps / deeplinks (optional)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        if let deeplink = info["deeplink"] as? String { print("Open deeplink:", deeplink) }
        completionHandler()
    }
}
