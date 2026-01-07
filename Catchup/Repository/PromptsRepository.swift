//
//  PromptsRepository.swift
//  Catchup
//
//  Created by Intat Tochirakul on 8/11/2568 BE.
//

import Foundation
import FirebaseFirestore

final class PromptsRepository {
    private let db = Firestore.firestore()

    func createGeneratedPrompt(_ text: String, category: QuestionCategory) async throws -> String {
        let now = Date()
        let pid = "generated_\(Int(now.timeIntervalSince1970))"
        let doc = db.collection("prompts").document(pid)
        let model = Prompt(
            promptId: pid,
            text: text,
            tags: [category.rawValue.lowercased()],
            type: "generated",
            activeFrom: now,
            activeTo: now.addingTimeInterval(7 * 24 * 3600),
            createdBy: "gpt",
            createdAt: now
        )
        try await doc.setData(PromptMapper.toDict(model), merge: true)
        return pid
    }
}
