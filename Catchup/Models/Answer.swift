//
//  Answer.swift
//  Catchup
//
//  Created by Intat Tochirakul on 8/11/2568 BE.
//

import Foundation
import FirebaseFirestore

struct Answer: Identifiable {
    var id: String { answerId }
    let answerId: String
    let promptId: String
    let promptText: String
    let authorUid: String
    let name: String
    let photoURL: String?
    let text: String
    let createdAt: Date
    let recipients: [String]  // list of UIDs
}

enum AnswerMapper {
    static func toDict(_ a: Answer) -> [String: Any] {
        [
            "promptId": a.promptId,
            "promptText": a.promptText,
            "authorUid": a.authorUid,
            "name": a.name,
            "photoURL": a.photoURL as Any,
            "text": a.text,
            "media": ["imageURL": NSNull(), "audioURL": NSNull()],
            "reaction": ["type": NSNull(), "createdAt": NSNull(), "updatedAt": NSNull()],
            "createdAt": Timestamp(date: a.createdAt),
            "recipients": a.recipients
        ]
    }
}
