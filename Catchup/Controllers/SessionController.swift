//
//  SessionController.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class SessionController: ObservableObject {
    @Published var user: User?

    private let usersRepo: UsersRepositoryType
    private let db = Firestore.firestore()

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var userListener: ListenerRegistration?

    init(usersRepo: UsersRepositoryType = UsersRepository()) {
        self.usersRepo = usersRepo

        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, current in
            Task { @MainActor in
                guard let self = self else { return }
                self.attachUserListener(for: current?.uid)
            }
        }
    }

    deinit {
        if let h = authHandle { Auth.auth().removeStateDidChangeListener(h) }
        userListener?.remove()
    }

    private func attachUserListener(for uid: String?) {
        // clean up previous
        userListener?.remove()
        user = nil
        guard let uid else { return }

        userListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snap, err in
                guard let self = self else { return }
                guard err == nil, let snap, let data = snap.data() else { return }
                if let u = try? UserMapper.user(from: data, uid: snap.documentID) {
                    self.user = u              // <- publishes updates to views immediately
                }
                
                LocalPushCoordinator.shared.ensureDailySchedules(
                                    pushEnabled: true,
                                    inAppNotification: true
                                )
            }
    }

    /// Optional: call this after writes if you don't want a live listener (or as a belt-and-suspenders).
    func refreshNow() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if let u = try? await usersRepo.get(uid: uid) {
            self.user = u
        }
    }
}
