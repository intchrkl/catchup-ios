//
//  UsersRepositoryUpdate.swift
//  Catchup
//
//  Created by Nick Jitjang on 11/9/25.
//

import FirebaseFirestore

extension UsersRepository {
    /// Merge updates to a user profile doc.
    func updateProfile(uid: String,
                       displayName: String? = nil,
                       username: String? = nil,
                       photoURL: String? = nil) async throws {
        let db = Firestore.firestore()
        var data: [String: Any] = ["updatedAt": Timestamp(date: Date())]
        if let displayName { data["displayName"] = displayName }
        if let username    { data["username"]    = username }
        if let photoURL    { data["photoURL"]    = photoURL }
        try await db.document("users/\(uid)").setData(data, merge: true)
    }
}
