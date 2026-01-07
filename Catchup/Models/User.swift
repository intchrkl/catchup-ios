//
//  User.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import Foundation

struct User: Codable, Identifiable {
    var id: String { uid }
    let uid: String
    let displayName: String
    let username: String
    let password_hash: String?      // not used; FirebaseAuth stores passwords securely
    let photoURL: String?
    let createdAt: Date
    let updatedAt: Date
    let stats: Stats
    let settings: Settings

    struct Stats: Codable { let answersCount: Int; let friendsCount: Int; let streakDays: Int }
    struct Settings: Codable { let inAppNotification: Bool; let pushEnabled: Bool; let timezone: String }
}
