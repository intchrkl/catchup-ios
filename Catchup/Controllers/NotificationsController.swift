//
//  NotificationsController.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import Foundation
import FirebaseAuth
import Combine
import SwiftUI

@MainActor
final class NotificationsController: ObservableObject {
    @Published var incoming: [AppNotificationLite] = []
    private let repo = NotificationsRepository()
    private let friendsRepo = FriendsRepository()
    private var streamTask: Task<Void, Never>?

    private var uid: String { Auth.auth().currentUser?.uid ?? "" }

    // Use inbox stream so we see BOTH friendRequest and answerShared
    func start() {
        guard !uid.isEmpty else { return }
        streamTask?.cancel()
        streamTask = Task { [uid, repo] in
            do {
                for try await items in repo.unreadInbox(for: uid) {
                    await MainActor.run { self.incoming = items }
                }
            } catch {
                print("notifications stream error:", error.localizedDescription)
            }
        }
    }

    deinit { streamTask?.cancel() }

    // MARK: - Friend requests

    func accept(_ n: AppNotificationLite,
                myDisplay: String, myUsername: String,
                otherDisplay: String, otherUsername: String) async {
        guard let otherUid = n.data["fromUid"] as? String else { return }
        let pid = friendsRepo.pairId(uid, otherUid)
        do {
            try await friendsRepo.accept(pairId: pid)
            try await repo.markRead(n.id)
            await MainActor.run {
                withAnimation { self.incoming.removeAll { $0.id == n.id } }
            }
        } catch {
            print("accept error:", error.localizedDescription)
        }
    }

    func decline(_ n: AppNotificationLite) async {
        guard let otherUid = n.data["fromUid"] as? String else { return }
        let pid = friendsRepo.pairId(uid, otherUid)
        let req = FriendRequestDTO(pairId: pid,
                                   userA: "",
                                   userB: "",
                                   status: "pending",
                                   requestedBy: "",
                                   createdAt: Date())
        do {
            try await friendsRepo.declineRequest(req)
            try await repo.markRead(n.id)
            await MainActor.run {
                withAnimation { self.incoming.removeAll { $0.id == n.id } }
            }
        } catch {
            print("decline error:", error.localizedDescription)
        }
    }

    // MARK: - Answer notifications

    /// Mark ONE notification as read and update local list
    func markRead(_ n: AppNotificationLite) async {
        do {
            try await repo.markRead(n.id)
            await MainActor.run {
                withAnimation { self.incoming.removeAll { $0.id == n.id } }
            }
        } catch {
            print("markRead error:", error.localizedDescription)
        }
    }

    /// Mark *all* answerShared as read (used when leaving notifications tab)
    func markAllAnswerSharedRead() async {
        let answerIds = incoming
            .filter { $0.type == "answerShared" }
            .map(\.id)

        guard !answerIds.isEmpty else { return }

        for id in answerIds {
            try? await repo.markRead(id)
        }

        await MainActor.run {
            withAnimation {
                self.incoming.removeAll { $0.type == "answerShared" }
            }
        }
    }

    // Computed for red dot / badge
    var hasUnread: Bool {
        !incoming.isEmpty
    }
}
