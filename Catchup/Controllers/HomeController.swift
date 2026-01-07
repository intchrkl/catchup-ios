//
//  HomeController.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class HomeController: ObservableObject {
    private let usersRepo = UsersRepository()
    private let answersRepo = AnswersRepository()

    @Published var heroAnswers: [AnswerCardVM] = []
    private var streamTask: Task<Void, Never>?

    init() { startStreaming(limit: 1) }
    deinit { streamTask?.cancel() }

    func startStreaming(limit: Int = 5) {
        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else {
            heroAnswers = []
            return
        }

        streamTask?.cancel()
        streamTask = Task { [answersRepo, usersRepo] in
            do {
                for try await docs in answersRepo.receivedAnswersStream(for: uid) {
                    let top = Array(docs.prefix(limit))

                    // Build authorUid -> photoURL map
                    var photoByUid: [String: String] = [:]
                    let authorUids = Array(Set(top.compactMap { $0.authorUid }))  // [String]
                    if !authorUids.isEmpty, let profiles = try? await usersRepo.getMany(uids: authorUids) {
                        for (id, user) in profiles {
                            if let p = user.photoURL, !p.isEmpty {
                                photoByUid[id] = p
                            }
                        }
                    }

                    let mapped: [AnswerCardVM] = top.map { d in
                        let auid = d.authorUid ?? ""
                        let photo = photoByUid[auid]  // String?
                        return AnswerCardVM(
                            id: d.id,
                            promptText: d.promptText,
                            authorName: d.name.isEmpty ? "Friend" : d.name,
                            authorPhotoURL: photo,
                            category: d.category,
                            createdAt: d.createdAt
                        )
                    }

                    await MainActor.run { self.heroAnswers = mapped }
                }
            } catch {
                // Optional: log error
                // print("HomeController stream error: \(error)")
            }
        }
    }


    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
    }
}

/// Lightweight VM for the hero card
struct AnswerCardVM: Identifiable, Hashable {
    let id: String
    let promptText: String
    let authorName: String
    let authorPhotoURL: String?   // used by the hero avatar
    let category: String?
    let createdAt: Date
}
