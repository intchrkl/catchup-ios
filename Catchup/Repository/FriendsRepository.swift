//
//  FriendsRepository.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import FirebaseFirestore

final class FriendsRepository: FriendsRepositoryType {
    private let db = Firestore.firestore()

    // Stable composite id to avoid duplicates
    func pairId(_ a: String, _ b: String) -> String { a < b ? "\(a)__\(b)" : "\(b)__\(a)" }

    func existingRequestBetween(_ a: String, _ b: String) async throws -> FriendRequestDTO? {
        let pid = pairId(a, b)
        let doc = try await db.collection("friendships").document(pid).getDocument()
        guard let v = doc.data() else { return nil }
        return FriendRequestDTO(
            pairId: pid,
            userA: v["userA"] as? String ?? "",
            userB: v["userB"] as? String ?? "",
            status: v["status"] as? String ?? "pending",
            requestedBy: v["requestedBy"] as? String ?? "",
            createdAt: (v["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    /// Write friend_requests/{pairId} with status "pending"
    func sendRequest(from uid: String, to otherUid: String) async throws -> FriendRequestDTO {
        let pid = pairId(uid, otherUid)
        let nowTs = Timestamp(date: Date())
        let data: [String: Any] = [
            "userA": uid,
            "userB": otherUid,
            "status": "pending",
            "requestedBy": uid,
            "createdAt": nowTs
        ]
        try await db.collection("friendships").document(pid).setData(data, merge: true)
        return FriendRequestDTO(pairId: pid, userA: uid, userB: otherUid, status: "pending", requestedBy: uid, createdAt: nowTs.dateValue())
    }
    func accept(pairId: String) async throws {
           let ref = db.collection("friendships").document(pairId)
           let snap = try await ref.getDocument()
           guard let v = snap.data(),
                 let userA = v["userA"] as? String,
                 let userB = v["userB"] as? String else {
               throw NSError(domain: "FriendsRepository", code: 400,
                             userInfo: [NSLocalizedDescriptionKey: "Invalid friendship doc"])
           }

           let now = Timestamp(date: Date())
           let batch = db.batch()

           // 1) status -> accepted
           batch.updateData(["status": "accepted"], forDocument: ref)

           // 2) write edge for A -> B
           let aEdge = db.document("users/\(userA)/friends/\(userB)")
           batch.setData([
               "friendUid": userB,
               "since": now,
               "sourcePairId": pairId,
               "streaks": 0
           ], forDocument: aEdge, merge: true)

           // 3) write edge for B -> A
           let bEdge = db.document("users/\(userB)/friends/\(userA)")
           batch.setData([
               "friendUid": userA,
               "since": now,
               "sourcePairId": pairId,
               "streaks": 0
           ], forDocument: bEdge, merge: true)

           try await batch.commit()
       }

    /// Accept request → set status=accepted + write users/{uid}/friends sub-docs
    func acceptRequest(_ req: FriendRequestDTO,
                       aDisplay: String, aUsername: String,
                       bDisplay: String, bUsername: String) async throws {
        // 1) status → accepted
        try await db.collection("friendships").document(req.pairId).updateData(["status": "accepted"])

        // 2) friend subdocs on both users
        let now = Timestamp(date: Date())
        let fa: [String: Any] = [
            "friendUid": req.userB,
            "friendName": bDisplay,
            "friendUsername": bUsername,
            "since": now,
            "sourcePairId": req.pairId,
            "streaks": 0
        ]
        let fb: [String: Any] = [
            "friendUid": req.userA,
            "friendName": aDisplay,
            "friendUsername": aUsername,
            "since": now,
            "sourcePairId": req.pairId,
            "streaks": 0
        ]
        try await db.document("users/\(req.userA)/friends/\(req.userB)").setData(fa, merge: true)
        try await db.document("users/\(req.userB)/friends/\(req.userA)").setData(fb, merge: true)
    }

    /// Decline request → status=declined
    func declineRequest(_ req: FriendRequestDTO) async throws {
        try await db.collection("friendships").document(req.pairId).updateData(["status": "declined"])
    }

    /// Live pending requests where current user is recipient (userB)
    func pendingIncoming(for uid: String) -> AsyncThrowingStream<[FriendRequestDTO], Error> {
        AsyncThrowingStream { continuation in
            let qs = db.collection("friendships")
                .whereField("userB", isEqualTo: uid)
                .whereField("status", isEqualTo: "pending")
            let listener = qs.addSnapshotListener { snap, err in
                if let err { continuation.yield(with: .failure(err)); return }
                let list = (snap?.documents ?? []).map { d -> FriendRequestDTO in
                    let v = d.data()
                    return FriendRequestDTO(
                        pairId: d.documentID,
                        userA: v["userA"] as? String ?? "",
                        userB: v["userB"] as? String ?? "",
                        status: v["status"] as? String ?? "pending",
                        requestedBy: v["requestedBy"] as? String ?? "",
                        createdAt: (v["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                continuation.yield(list)
            }
            continuation.onTermination = { _ in listener.remove() }
        }
    }
}

