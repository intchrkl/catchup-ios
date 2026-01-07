//
//  SentAnswersController.swift
//  Catchup
//
//  Created by Intat Tochirakul on 28/11/2568 BE.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
final class SentAnswersController: ObservableObject {
    @Published var items: [AnswerReelVM] = []
    @Published var currentIndex: Int = 0

    private let repo = AnswersRepository()
    private var streamTask: Task<Void, Never>?
    private let uid: String

    init(uid: String = Auth.auth().currentUser?.uid ?? "") {
        self.uid = uid
    }

    func start() {
        guard streamTask == nil, !uid.isEmpty else { return }

        streamTask = Task { [uid, repo] in
            do {
                for try await docs in repo.sentAnswersStream(for: uid) {
                    let vms = docs.map { AnswerReelVM(answer: $0) }
                    await MainActor.run {
                        self.items = vms
                        if self.currentIndex >= self.items.count {
                            self.currentIndex = max(0, self.items.count - 1)
                        }
                    }
                }
            } catch {
                // TODO: handle error if you want
            }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
    }
}
