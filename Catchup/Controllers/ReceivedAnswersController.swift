//
//  ReceivedAnswersController.swift
//  Catchup
//
//  Created by Eric Lin on 11/8/25.
//
// Controller/ReceivedAnswersController.swift
import Foundation
import FirebaseAuth
import Combine

struct AnswerReelVM: Identifiable {
    var id: String { answer.id }
    let answer: AnswerDoc
    // Optional: add username/photo fallbacks later if needed
}

@MainActor
final class ReceivedAnswersController: ObservableObject {
    @Published var items: [AnswerReelVM] = []
    @Published var currentIndex: Int = 0
    private let answersRepo = AnswersRepository()

    private var uid: String { Auth.auth().currentUser?.uid ?? "" }
    private var streamTask: Task<Void, Never>?

    func start() {
        guard !uid.isEmpty else { return }
        streamTask?.cancel()
        streamTask = Task { [uid, answersRepo] in
            do {
                for try await docs in answersRepo.receivedAnswersStream(for: uid) {
                    await MainActor.run {
                        self.items = docs.map { AnswerReelVM(answer: $0) }
                    }
                }
            } catch {
                // propagate error to UI if needed
            }
        }
    }

    func stop() { streamTask?.cancel(); streamTask = nil }
}

