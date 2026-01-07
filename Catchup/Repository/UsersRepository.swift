//
//  UsersRepository.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

// Repository/UsersRepository.swift
import Foundation
import FirebaseFirestore

protocol UsersRepositoryType {
    func get(uid: String) async throws -> User
    func createUserDoc(_ user: User) async throws
    func usernameExists(_ username: String) async throws -> Bool
}

final class UsersRepository: UsersRepositoryType {
    fileprivate let db: Firestore
    init(db: Firestore = FirebaseService.shared.db) { self.db = db }

    func get(uid: String) async throws -> User {
        let ref = db.document("users/\(uid)")
        let snap = try await ref.getDocument()
        guard let data = snap.data() else { throw NSError(domain: "UsersRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "User doc not found"]) }
        return try UserMapper.user(from: data, uid: uid)
    }

    func createUserDoc(_ user: User) async throws {
        let data = UserMapper.dict(from: user)
        try await db.document("users/\(user.uid)").setData(data, merge: true)
    }

    func usernameExists(_ username: String) async throws -> Bool {
        let snap = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()
        return !snap.documents.isEmpty
    }
}

// MARK: - Mapping between User and [String: Any] (no FirestoreSwift needed)
enum UserMapper {
    static func dict(from u: User) -> [String: Any] {
        [
            "uid": u.uid,
            "displayName": u.displayName,
            "username": u.username,
            "password_hash": NSNull(),                       // don't store real password
            "photoURL": u.photoURL as Any,
            "createdAt": Timestamp(date: u.createdAt),
            "updatedAt": Timestamp(date: u.updatedAt),
            "stats": [
                "answersCount": u.stats.answersCount,
                "friendsCount": u.stats.friendsCount,
                "streakDays": u.stats.streakDays
            ],
            "settings": [
                "inAppNotification": u.settings.inAppNotification,
                "pushEnabled": u.settings.pushEnabled,
                "timezone": u.settings.timezone
            ]
        ]
    }

    static func user(from data: [String: Any], uid: String) throws -> User {
        func ts(_ k: String) -> Date {
            (data[k] as? Timestamp)?.dateValue() ?? Date()
        }
        let stats = data["stats"] as? [String: Any] ?? [:]
        let settings = data["settings"] as? [String: Any] ?? [:]
        return User(
            uid: uid,
            displayName: data["displayName"] as? String ?? "",
            username: data["username"] as? String ?? "",
            password_hash: data["password_hash"] as? String,               // will likely be nil
            photoURL: data["photoURL"] as? String,
            createdAt: ts("createdAt"),
            updatedAt: ts("updatedAt"),
            stats: .init(
                answersCount: stats["answersCount"] as? Int ?? 0,
                friendsCount: stats["friendsCount"] as? Int ?? 0,
                streakDays:   stats["streakDays"]   as? Int ?? 0
            ),
            settings: .init(
                inAppNotification: settings["inAppNotification"] as? Bool ?? true,
                pushEnabled:       settings["pushEnabled"]       as? Bool ?? true,
                timezone:          settings["timezone"]          as? String ?? TimeZone.current.identifier
            )
        )
    }
}

