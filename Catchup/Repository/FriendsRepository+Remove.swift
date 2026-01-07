//
//  FriendsRepository+Remove.swift
//  Catchup
//
//  Created by Intat Tochirakul on 8/11/2568 BE.
//

// Repository/FriendsRepository+Remove.swift
import FirebaseFirestore

extension FriendsRepository {
    /// Remove friendship edges for both users and mark composite friendship as "removed".
    func removeFriendship(between a: String, and b: String) async throws {
        let pid = pairId(a, b)
        let db = Firestore.firestore()

        let batch = db.batch()
        let aEdge = db.document("users/\(a)/friends/\(b)")
        let bEdge = db.document("users/\(b)/friends/\(a)")
        let pair  = db.collection("friendships").document(pid)

        batch.deleteDocument(aEdge)
        batch.deleteDocument(bEdge)
        batch.setData([
            "status": "removed",
            "updatedAt": Timestamp(date: Date())
        ], forDocument: pair, merge: true)

        try await batch.commit()
    }
}
