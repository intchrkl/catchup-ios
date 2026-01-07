//
//  AuthController.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import FirebaseAuth
import Combine

@MainActor
final class AuthController: ObservableObject {
    @Published var isBusy = false
    @Published var errorMessage: String?

    private let usersRepo: UsersRepositoryType
    private let service = FirebaseService.shared

    init(usersRepo: UsersRepositoryType = UsersRepository()) {
        self.usersRepo = usersRepo
    }

    func signUp(displayName: String, username: String, email: String, password: String) async {
        guard !displayName.isEmpty, !username.isEmpty else { errorMessage = "Fill all fields."; return }
        isBusy = true; defer { isBusy = false }
        do {
            let result = try await service.auth.createUser(withEmail: email, password: password)
            let user = result.user

            // Check username availability after auth
            if try await usersRepo.usernameExists(username) {
                // Attempt to clean up the just-created auth user
                do {
                    try await user.delete()
                } catch {
                }
                errorMessage = "Username already taken."
                return
            }
            let uid = result.user.uid
            let now = Date()
            let userDoc = User(
                uid: uid,
                displayName: displayName,
                username: username,
                password_hash: nil,                         // do not store passwords here
                photoURL: nil,
                createdAt: now,
                updatedAt: now,
                stats: .init(answersCount: 0, friendsCount: 0, streakDays: 0),
                settings: .init(inAppNotification: true, pushEnabled: true, timezone: TimeZone.current.identifier)
            )
            try await usersRepo.createUserDoc(userDoc)
            var changeRequest = result.user.createProfileChangeRequest()
            try await changeRequest.setDisplayName(displayName)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        isBusy = true; defer { isBusy = false }
        do {
            _ = try await service.auth.signIn(withEmail: email, password: password)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        try? service.auth.signOut()
    }
}

private extension UserProfileChangeRequest {
    func setDisplayName(_ value: String) async throws {
        var req = self
        req.displayName = value
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            req.commitChanges { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }
}

