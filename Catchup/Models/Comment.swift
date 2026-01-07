//
//  Comment.swift
//  Catchup
//
//  Created by Eric Lin on 11/19/25.
//

import Foundation
import FirebaseFirestore

struct Comment: Identifiable {
    let id: String
    let authorUid: String
    let authorName: String
    let text: String
    let createdAt: Date

    init(id: String,
         authorUid: String,
         authorName: String,
         text: String,
         createdAt: Date) {
        self.id = id
        self.authorUid = authorUid
        self.authorName = authorName
        self.text = text
        self.createdAt = createdAt
    }

    init?(doc: DocumentSnapshot) {
        let data = doc.data() ?? [:]

        guard
            let authorUid = data["authorUid"] as? String,
            let authorName = data["authorName"] as? String,
            let text = data["text"] as? String,
            let ts = data["createdAt"] as? Timestamp
        else { return nil }

        self.init(
            id: doc.documentID,
            authorUid: authorUid,
            authorName: authorName,
            text: text,
            createdAt: ts.dateValue()
        )
    }

    var dict: [String: Any] {
        [
            "authorUid": authorUid,
            "authorName": authorName,
            "text": text,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
