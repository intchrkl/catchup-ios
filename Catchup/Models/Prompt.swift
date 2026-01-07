//
//  Prompt.swift
//  Catchup
//
//  Created by Intat Tochirakul on 8/11/2568 BE.
//

import Foundation
import FirebaseFirestore

struct Prompt: Identifiable {
    var id: String { promptId }
    let promptId: String      // e.g., "generated_<timestamp>" or firestore doc id
    let text: String
    let tags: [String]
    let type: String          // "generated"
    let activeFrom: Date
    let activeTo: Date
    let createdBy: String     // "system" | "user" | "gpt"
    let createdAt: Date
}

enum PromptMapper {
    static func toDict(_ p: Prompt) -> [String: Any] {
        [
            "text": p.text,
            "tags": p.tags,
            "type": p.type,
            "activeFrom": Timestamp(date: p.activeFrom),
            "activeTo": Timestamp(date: p.activeTo),
            "createdBy": p.createdBy,
            "createdAt": Timestamp(date: p.createdAt)
        ]
    }
}
