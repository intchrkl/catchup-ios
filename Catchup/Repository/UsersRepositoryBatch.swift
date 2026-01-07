//
//  UsersRepositoryBatch.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import FirebaseFirestore

extension UsersRepository {
    func getMany(uids: [String]) async throws -> [String: User] {
        let db = Firestore.firestore()
        guard !uids.isEmpty else { return [:] }
        var out: [String: User] = [:]

        // Firestore "in" queries allow up to 10 items; chunk if needed
        let chunks = stride(from: 0, to: uids.count, by: 10)
            .map { Array(uids[$0..<min($0+10, uids.count)]) }

        for ids in chunks {
            let q = db.collection("users")
                .whereField(FieldPath.documentID(), in: ids)
            let snap = try await q.getDocuments()
            for d in snap.documents {
                if let user = try? UserMapper.user(from: d.data(), uid: d.documentID) {
                    out[d.documentID] = user
                }
            }
        }
        return out
    }
}
