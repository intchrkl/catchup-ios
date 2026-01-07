//
//  FriendRepositoryList.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import FirebaseFirestore

extension FriendsRepository {
    func friendsOnce(for uid: String) async throws -> [FriendLite] {
        let snap = try await Firestore.firestore()
            .collection("users").document(uid)
            .collection("friends")
            .order(by: "since", descending: true)
            .getDocuments()

        return snap.documents.compactMap { d in
            let v = d.data()
            return FriendLite(
                friendUid: v["friendUid"] as? String ?? d.documentID,
                friendName: v["friendName"] as? String ?? "",
                friendUsername: v["friendUsername"] as? String ?? "",
                since: (v["since"] as? Timestamp)?.dateValue() ?? Date(),
                sourcePairId: v["sourcePairId"] as? String ?? "",
                streaks: v["streaks"] as? Int ?? 0
            )
        }
    }

    func friendsStream(for uid: String) -> AsyncThrowingStream<[FriendLite], Error> {
        AsyncThrowingStream { continuation in
            let qs = Firestore.firestore()
                .collection("users").document(uid)
                .collection("friends")
                .order(by: "since", descending: true)

            let listener = qs.addSnapshotListener { snap, err in
                if let err { continuation.yield(with: .failure(err)); return }
                let list = (snap?.documents ?? []).compactMap { d -> FriendLite? in
                    let v = d.data()
                    return FriendLite(
                        friendUid: v["friendUid"] as? String ?? d.documentID,
                        friendName: v["friendName"] as? String ?? "",
                        friendUsername: v["friendUsername"] as? String ?? "",
                        since: (v["since"] as? Timestamp)?.dateValue() ?? Date(),
                        sourcePairId: v["sourcePairId"] as? String ?? "",
                        streaks: v["streaks"] as? Int ?? 0
                    )
                }
                continuation.yield(list)
            }
            continuation.onTermination = { _ in listener.remove() }
        }
    }
}
