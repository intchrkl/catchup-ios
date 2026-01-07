//
//  MyFriendsController.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
class MyFriendsController: ObservableObject {
    @Published var friends: [FriendRowVM] = []
    @Published var isLoading = false

    private let friendsRepo = FriendsRepository()
    private let usersRepo = UsersRepository()
    private var uid: String { Auth.auth().currentUser?.uid ?? "" }

    func start() {
        guard !uid.isEmpty else { return }
        Task {
            for try await edges in friendsRepo.friendsStream(for: uid) {
                await loadProfiles(for: edges)
            }
        }
    }

    func refresh() async {
        guard !uid.isEmpty else { return }
        isLoading = true; defer { isLoading = false }
        let edges = (try? await friendsRepo.friendsOnce(for: uid)) ?? []
        await loadProfiles(for: edges)
    }
    
    
    func remove(friend: FriendRowVM) async {
        guard let me = Auth.auth().currentUser?.uid else { return }
        do {
            try await friendsRepo.removeFriendship(between: me, and: friend.uid)
            // Optimistic UI update
            friends.removeAll { $0.uid == friend.uid }
        } catch {
            print("remove friend error:", error.localizedDescription)
        }
    }

    // MARK: - Helpers

    func loadProfiles(for edges: [FriendLite]) async {
        let ids = edges.map { $0.friendUid }
        do {
            let profiles = try await usersRepo.getMany(uids: ids)

            let rows: [FriendRowVM] = edges.compactMap { e in
                let streakVal = e.streaks  // ← read streak from FriendLite

                if let u = profiles[e.friendUid] {
                    return FriendRowVM(
                        uid: u.uid,
                        displayName: u.displayName.isEmpty ? "Friend" : u.displayName,
                        username: u.username.isEmpty ? "unknown" : u.username,
                        photoURL: u.photoURL,
                        since: e.since,
                        streaks: streakVal           // ← ADD
                    )
                } else {
                    return FriendRowVM(
                        uid: e.friendUid,
                        displayName: "Friend",
                        username: "unknown",
                        photoURL: nil,
                        since: e.since,
                        streaks: streakVal           // ← ADD
                    )
                }
            }

            self.friends = rows.sorted { $0.since > $1.since }
        } catch {
            await loadProfilesIndividually(for: edges)
        }
    }


    // Fallback: fetch each user one-by-one (slower but robust)
    func loadProfilesIndividually(for edges: [FriendLite]) async {
        var rows: [FriendRowVM] = []

        for e in edges {
            let streakVal = e.streaks   // ← ADD

            if let u = try? await usersRepo.get(uid: e.friendUid) {
                rows.append(FriendRowVM(
                    uid: u.uid,
                    displayName: u.displayName.isEmpty ? "Friend" : u.displayName,
                    username: u.username.isEmpty ? "unknown" : u.username,
                    photoURL: u.photoURL,
                    since: e.since,
                    streaks: streakVal         // ← ADD
                ))
            } else {
                rows.append(FriendRowVM(
                    uid: e.friendUid,
                    displayName: "Friend",
                    username: "unknown",
                    photoURL: nil,
                    since: e.since,
                    streaks: streakVal         // ← ADD
                ))
            }
        }

        self.friends = rows.sorted { $0.since > $1.since }
    }

}
