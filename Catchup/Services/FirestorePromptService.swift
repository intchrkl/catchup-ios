//
//  FirestorePromptService.swift
//  Catchup
//
//  Created by Intat Tochirakul on 21/11/2568 BE.
//

// FirestorePromptService.swift
import Foundation
import FirebaseFirestore

struct FirestorePromptService: PromptServiceType {
    private let db = Firestore.firestore()

    func generateQuestion(for category: QuestionCategory) async throws -> String {
        // Use the enum rawValue as the document ID, e.g. "Self Reflection"
        let docId = category.rawValue

        let snapshot = try await db
            .collection("questions")
            .document(docId)
            .getDocument()

        guard let data = snapshot.data() else {
            throw NSError(
                domain: "PromptService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No data for category \(docId)"]
            )
        }

        guard let questions = data["questions"] as? [String],
              !questions.isEmpty else {
            throw NSError(
                domain: "PromptService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "No questions for category \(docId)"]
            )
        }

        // Pick a random question
        return questions.randomElement() ?? questions[0]
    }
}
