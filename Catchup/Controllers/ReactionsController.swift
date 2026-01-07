//
//  ReactionsController.swift
//  Catchup
//
//  Created by Intat Tochirakul on 20/11/2568 BE.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
final class ReactionsController: ObservableObject {
    @Published var counts: [String: Int] = [:]        // emoji -> total count
    @Published var userReactions: Set<String> = []    // emojis current user has used

    private let answer: AnswerDoc
    private let repo = AnswersRepository()
    private let currentUid: String
    private var streamTask: Task<Void, Never>?

    init(answer: AnswerDoc, currentUid: String) {
        self.answer = answer
        self.currentUid = currentUid
    }

    func start() {
        guard streamTask == nil else { return }

        streamTask = Task { [answer, repo, currentUid] in
            do {
                for try await items in repo.reactionsStream(for: answer.id) {
                    // Recompute aggregate counts & user set
                    var newCounts: [String: Int] = [:]
                    var mySet: Set<String> = []

                    for r in items {
                        newCounts[r.emoji, default: 0] += 1
                        if r.userUid == currentUid {
                            mySet.insert(r.emoji)
                        }
                    }

                    await MainActor.run {
                        self.counts = newCounts
                        self.userReactions = mySet
                    }
                }
            } catch {
                // Optional: handle error
            }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
    }

    func toggle(emoji: String) async {
        guard !currentUid.isEmpty else { return }
        do {
            try await repo.toggleReaction(
                for: answer.id,
                emoji: emoji,
                userUid: currentUid
            )
        } catch {
            // Optional: handle error
        }
    }
}
