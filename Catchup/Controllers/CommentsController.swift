//
//  CommentsController.swift
//  Catchup
//
//  Created by Eric Lin on 11/19/25.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
final class CommentsController: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var newText: String = ""

    let answer: AnswerDoc
    private let repo = AnswersRepository()
    private var streamTask: Task<Void, Never>?

    init(answer: AnswerDoc) {
        self.answer = answer
    }

    func start() {
        guard streamTask == nil else { return }

        streamTask = Task { [answer, repo] in
            do {
                for try await items in repo.commentsStream(for: answer.id) {
                    await MainActor.run {
                        self.comments = items
                    }
                }
            } catch {
                // TODO: propagate error if needed
            }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
    }

    func sendComment() async {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let user = Auth.auth().currentUser else { return }

        let displayName = user.displayName ?? "Someone"

        do {
            try await repo.addComment(
                to: answer.id,
                authorUid: user.uid,
                authorName: displayName,
                text: trimmed
            )
            await MainActor.run {
                self.newText = ""
            }
        } catch {
            // TODO: handle error (toast, etc.)
        }
    }
}
