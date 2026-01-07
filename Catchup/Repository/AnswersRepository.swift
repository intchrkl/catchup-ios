//
//  AnswersRepository.swift
//  Catchup
//
//  Created by Intat Tochirakul on 8/11/2568 BE.
//

// Repository/AnswersRepository.swift
import Foundation
import FirebaseFirestore

struct AnswerDoc: Identifiable {
    let id: String
    let promptText: String
    let category: String?
    let authorUid: String
    let name: String
    let photoURL: String?
    let text: String
    let createdAt: Date
    let recipients: [String]
}

final class AnswersRepository: AnswersRepositoryType {
    private let db = Firestore.firestore()

    /// Create a text-only answer and return its id.
    func createAnswer(
        promptText: String,
        category: String?,
        author: User,
        text: String,
        recipients: [String]
    ) async throws -> String {
        let doc = db.collection("answers").document()
        let data: [String: Any] = [
            "promptText": promptText,
            "category": category as Any,
            "authorUid": author.uid,
            "name": author.displayName,
            "photoURL": author.photoURL as Any,
            "text": text,
            "createdAt": Timestamp(date: Date()),
            "recipients": recipients
        ]
        try await doc.setData(data)
        return doc.documentID
    }

    /// Stream of received answers for a user, newest first.
    func receivedAnswersStream(for uid: String) -> AsyncThrowingStream<[AnswerDoc], Error> {
        AsyncThrowingStream { continuation in
            // Note: This query may require a Firestore composite index:
            // answers where recipients array-contains + order by createdAt desc
            let qs = db.collection("answers")
                .whereField("recipients", arrayContains: uid)
                .order(by: "createdAt", descending: true)

            let listener = qs.addSnapshotListener { snap, err in
                if let err { continuation.yield(with: .failure(err)); return }
                let items: [AnswerDoc] = (snap?.documents ?? []).compactMap { d in
                    let v = d.data()
                    return AnswerDoc(
                        id: d.documentID,
                        promptText: v["promptText"] as? String ?? "",
                        category: v["category"] as? String,
                        authorUid: v["authorUid"] as? String ?? "",
                        name: v["name"] as? String ?? "",
                        photoURL: v["photoURL"] as? String,
                        text: v["text"] as? String ?? "",
                        createdAt: (v["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        recipients: v["recipients"] as? [String] ?? []
                    )
                }
                continuation.yield(items)
            }
            continuation.onTermination = { _ in listener.remove() }
        }
    }
}

extension AnswersRepository {

    /// Stream comments for one answer (oldest first).
    func commentsStream(for answerId: String)
        -> AsyncThrowingStream<[Comment], Error>
    {
        AsyncThrowingStream { continuation in
            let query = db.collection("answers")
                .document(answerId)
                .collection("comments")
                .order(by: "createdAt", descending: false)

            let listener = query.addSnapshotListener { snapshot, error in
                if let error {
                    continuation.yield(with: .failure(error))
                    return
                }

                let comments = (snapshot?.documents ?? [])
                    .compactMap { Comment(doc: $0) }

                continuation.yield(comments)
            }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    /// Add a new comment to an answer.
    func addComment(
        to answerId: String,
        authorUid: String,
        authorName: String,
        text: String
    ) async throws {
        let commentsRef = db.collection("answers")
            .document(answerId)
            .collection("comments")

        let doc = commentsRef.document()

        let data: [String: Any] = [
            "authorUid": authorUid,
            "authorName": authorName,
            "text": text,
            "createdAt": Timestamp(date: Date())
        ]

        try await doc.setData(data)
    }
}

// MARK: - Reactions

extension AnswersRepository {

    /// Stream reactions for one answer.
    func reactionsStream(for answerId: String)
        -> AsyncThrowingStream<[Reaction], Error>
    {
        AsyncThrowingStream { continuation in
            let query = db.collection("answers")
                .document(answerId)
                .collection("reactions")

            let listener = query.addSnapshotListener { snapshot, error in
                if let error {
                    continuation.yield(with: .failure(error))
                    return
                }

                let reactions = (snapshot?.documents ?? [])
                    .compactMap { Reaction(doc: $0) }

                continuation.yield(reactions)
            }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    /// Toggle one emoji reaction for a given user on a given answer.
    func toggleReaction(
        for answerId: String,
        emoji: String,
        userUid: String
    ) async throws {
        let reactionsRef = db.collection("answers")
            .document(answerId)
            .collection("reactions")

        // Deterministic doc id: emoji + user
        let docId = "\(emoji)_\(userUid)"
        let docRef = reactionsRef.document(docId)

        let snapshot = try await docRef.getDocument()
        if snapshot.exists {
            // User already reacted with this emoji → remove
            try await docRef.delete()
        } else {
            // Add reaction
            let data: [String: Any] = [
                "emoji": emoji,
                "userUid": userUid,
                "createdAt": Timestamp(date: Date())
            ]
            try await docRef.setData(data)
        }
    }
}

extension AnswersRepository {
    /// Stream of answers the user has SENT (authored), newest first.
    func sentAnswersStream(for uid: String) -> AsyncThrowingStream<[AnswerDoc], Error> {
        AsyncThrowingStream { continuation in
            let qs = db.collection("answers")
                .whereField("authorUid", isEqualTo: uid)
                .order(by: "createdAt", descending: true)

            let listener = qs.addSnapshotListener { snap, err in
                if let err {
                    continuation.yield(with: .failure(err))
                    return
                }

                let items: [AnswerDoc] = (snap?.documents ?? []).compactMap { d in
                    let v = d.data()
                    return AnswerDoc(
                        id: d.documentID,
                        promptText: v["promptText"] as? String ?? "",
                        category: v["category"] as? String,
                        authorUid: v["authorUid"] as? String ?? "",
                        name: v["name"] as? String ?? "",
                        photoURL: v["photoURL"] as? String,
                        text: v["text"] as? String ?? "",
                        createdAt: (v["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        recipients: v["recipients"] as? [String] ?? []
                    )
                }
                continuation.yield(items)
            }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}
