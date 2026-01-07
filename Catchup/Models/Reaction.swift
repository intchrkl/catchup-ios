//
//  Reaction.swift
//  Catchup
//
//  Created by Intat Tochirakul on 20/11/2568 BE.
//

import Foundation
import FirebaseFirestore

struct Reaction: Identifiable {
    let id: String
    let emoji: String
    let userUid: String
    let createdAt: Date

    init(id: String,
         emoji: String,
         userUid: String,
         createdAt: Date) {
        self.id = id
        self.emoji = emoji
        self.userUid = userUid
        self.createdAt = createdAt
    }

    init?(doc: DocumentSnapshot) {
        let data = doc.data() ?? [:]

        guard
            let emoji = data["emoji"] as? String,
            let userUid = data["userUid"] as? String,
            let ts = data["createdAt"] as? Timestamp
        else {
            return nil
        }

        self.init(
            id: doc.documentID,
            emoji: emoji,
            userUid: userUid,
            createdAt: ts.dateValue()
        )
    }

    var dict: [String: Any] {
        [
            "emoji": emoji,
            "userUid": userUid,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
