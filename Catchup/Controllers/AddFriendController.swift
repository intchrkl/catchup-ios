//
//  AddFriendController.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

// Controller/AddFriendController.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

struct UserLite: Identifiable {
    var id: String { uid }
    let uid: String
    let displayName: String
    let username: String
    let photoURL: String?
}

@MainActor
final class AddFriendController: ObservableObject {
    @Published var query: String = ""
    @Published var results: [UserLite] = []
    @Published var sending: Set<String> = []
    @Published var sentTo: Set<String> = []
    @Published var existingFriends: Set<String> = []

    private let usersRepo = UsersRepository()
    private let friendsRepo = FriendsRepository()
    private let notifRepo  = NotificationsRepository()

    private var myUid: String { Auth.auth().currentUser?.uid ?? "" }

    private var myDisplay: String = "Someone"
    private var myUsername: String = "unknown"

    init() {
        Task { await loadMe() }
    }

    private func loadMe() async {
        guard !myUid.isEmpty else { return }
        if let me = try? await usersRepo.get(uid: myUid) {
            myDisplay  = me.displayName.isEmpty ? "Someone" : me.displayName
            myUsername = me.username.isEmpty ? "unknown" : me.username
        }
    }

    // Username prefix search
    func search() async {
        guard !query.isEmpty else {
            results = []
            sentTo.removeAll()
            existingFriends.removeAll()
            return
        }

        let end = query + "\u{f8ff}"
        let snap = try? await Firestore.firestore().collection("users")
            .order(by: "username")
            .start(at: [query])
            .end(at: [end])
            .limit(to: 15)
            .getDocuments()

        var users = (snap?.documents ?? []).compactMap { d -> UserLite? in
            let v = d.data()
            guard let name = v["displayName"] as? String,
                  let uname = v["username"] as? String else { return nil }
            let photo = v["photoURL"] as? String
            return UserLite(uid: d.documentID, displayName: name, username: uname, photoURL: photo)
        }

        users.removeAll { $0.uid == myUid }

        results = users
        await refreshSentState()
    }

    func refreshSentState() async {
        sentTo.removeAll()
        existingFriends.removeAll()

        for u in results {
            if let req = try? await friendsRepo.existingRequestBetween(myUid, u.uid) {
                switch req.status {
                case "pending":
                    sentTo.insert(u.uid)          // already requested
                case "accepted":
                    existingFriends.insert(u.uid) // already friends
                default:
                    break
                }
            }
        }
    }

    func sendRequest(to target: UserLite) async {
        guard !myUid.isEmpty, myUid != target.uid else { return }

        // Don’t send a request if already friends
        if existingFriends.contains(target.uid) {
            return
        }

        if myUsername == "unknown" || myDisplay == "Someone" {
            await loadMe()
        }

        sending.insert(target.uid); defer { sending.remove(target.uid) }
        do {
            _ = try await friendsRepo.sendRequest(from: myUid, to: target.uid)
            try await notifRepo.createFriendRequestNotification(
                recipientUid: target.uid,
                fromUid: myUid,
                fromName: myDisplay,
                fromUsername: myUsername
            )
            sentTo.insert(target.uid)
        } catch {
            print("send req error:", error.localizedDescription)
        }
    }
}
