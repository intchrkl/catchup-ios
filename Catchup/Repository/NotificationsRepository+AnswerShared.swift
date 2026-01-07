//
//  NotificationsRepository+AnswerShared.swift
//  Catchup
//
//  Created by Intat Tochirakul on 8/11/2568 BE.
//

import FirebaseFirestore

extension NotificationsRepository {
    /// Create a notification when an answer is shared with a friend
    func notifyAnswerShared(from author: User, to recipientUid: String, answerId: String) async throws {
        let doc = Firestore.firestore().collection("notifications").document()
        let data: [String: Any] = [
            "recipientUid": recipientUid,
            "type": "answerShared",
            "data": [
                "answerId": answerId,
                "fromUid": author.uid,
                "fromName": author.displayName,
                "fromUsername": author.username
            ],
            "read": false,
            "createdAt": Timestamp(date: Date())
        ]
        try await doc.setData(data, merge: true)
    }
}
