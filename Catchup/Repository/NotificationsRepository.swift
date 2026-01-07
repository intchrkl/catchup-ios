//
//  NotificationsRepository.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

// Repository/NotificationsRepository.swift
import FirebaseFirestore

struct AppNotificationLite: Identifiable {
    let id: String
    let recipientUid: String
    let type: String
    let data: [String: Any]
    let read: Bool
    let createdAt: Date
}

final class NotificationsRepository: NotificationsRepositoryType {
    private let db = Firestore.firestore()

    /// Create a friendRequest notification for the recipient
    func createFriendRequestNotification(recipientUid: String,
                                         fromUid: String,
                                         fromName: String,
                                         fromUsername: String) async throws {
        let id = UUID().uuidString
        let payload: [String: Any] = [
            "recipientUid": recipientUid,
            "type": "friendRequest",
            "data": [
                "answerId": NSNull(),
                "fromUid": fromUid,
                "fromName": fromName,
                "fromUsername": fromUsername
            ],
            "read": false,
            "createdAt": Timestamp(date: Date())
        ]
        try await db.collection("notifications").document(id).setData(payload)
    }

    func unreadFriendRequests(for uid: String) -> AsyncThrowingStream<[AppNotificationLite], Error> {
        AsyncThrowingStream { continuation in
            let qs = db.collection("notifications")
                .whereField("recipientUid", isEqualTo: uid)
                .whereField("type", isEqualTo: "friendRequest")
                .whereField("read", isEqualTo: false)
                .order(by: "createdAt", descending: true)
            let listener = qs.addSnapshotListener { snap, err in
                if let err { continuation.yield(with: .failure(err)); return }
                let list = (snap?.documents ?? []).map { d -> AppNotificationLite in
                    let v = d.data()
                    return AppNotificationLite(
                        id: d.documentID,
                        recipientUid: v["recipientUid"] as? String ?? "",
                        type: v["type"] as? String ?? "",
                        data: v["data"] as? [String: Any] ?? [:],
                        read: v["read"] as? Bool ?? false,
                        createdAt: (v["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                continuation.yield(list)
            }
            continuation.onTermination = { _ in listener.remove() }
        }
    }
    
    // Unified inbox: all unread notifications (friend requests + answers, etc.)

    func unreadInbox(for uid: String) -> AsyncThrowingStream<[AppNotificationLite], Error> {
        AsyncThrowingStream { continuation in
            let qs = db.collection("notifications")
                .whereField("recipientUid", isEqualTo: uid)
                .whereField("read", isEqualTo: false)
                .order(by: "createdAt", descending: true)

            let listener = qs.addSnapshotListener { snap, err in
                if let err {
                    continuation.yield(with: .failure(err))
                    return
                }
                let list = (snap?.documents ?? []).map { d -> AppNotificationLite in
                    let v = d.data()
                    return AppNotificationLite(
                        id: d.documentID,
                        recipientUid: v["recipientUid"] as? String ?? "",
                        type: v["type"] as? String ?? "",
                        data: v["data"] as? [String: Any] ?? [:],
                        read: v["read"] as? Bool ?? false,
                        createdAt: (v["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                continuation.yield(list)
            }

            continuation.onTermination = { _ in listener.remove() }
        }
    }



    func markRead(_ id: String) async throws {
        try await db.collection("notifications").document(id).updateData(["read": true])
    }
}

