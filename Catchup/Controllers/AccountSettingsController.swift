//
//  AccountSettingsController.swift
//  Catchup
//
//  Created by Nick Jitjang on 11/9/25.
//
import Foundation
import FirebaseAuth
import PhotosUI
import UIKit
import Combine
import _PhotosUI_SwiftUI

@MainActor
final class AccountSettingsController: ObservableObject {
    @Published var displayName: String = ""
    @Published var username: String = ""
    @Published var currentPhotoURL: String?
    @Published var pickedItem: PhotosPickerItem?
    @Published var pickedImageData: Data?

    @Published var isSaving = false
    @Published var errorMessage: String?

    private let usersRepo = UsersRepository()
    private let storage   = StorageService.shared
    private var uid: String { Auth.auth().currentUser?.uid ?? "" }

    func loadCurrent() async {
        guard !uid.isEmpty else { return }
        do {
            let me = try await usersRepo.get(uid: uid)
            displayName     = me.displayName
            username        = me.username
            currentPhotoURL = me.photoURL
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func handlePickChange() {
        guard let item = pickedItem else { pickedImageData = nil; return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                pickedImageData = compressJPEGIfNeeded(data)
            }
        }
    }

    func save() async {
        guard !uid.isEmpty else { return }
        isSaving = true; defer { isSaving = false }
        errorMessage = nil

        do {
            // Validate username only if changed
            let current = try await usersRepo.get(uid: uid)
            if username != current.username, try await usersRepo.usernameExists(username) {
                errorMessage = "That username is taken."
                return
            }

            // Upload avatar if picked
            var photoURLToSave: String? = nil
            if let data = pickedImageData {
                photoURLToSave = try await storage.uploadAvatar(uid: uid, data: data, contentType: "image/jpeg")
            }

            // Update Firestore profile (UsersRepository.updateProfile only sets non-nil fields)
            try await usersRepo.updateProfile(uid: uid,
                                              displayName: displayName,
                                              username: username,
                                              photoURL: photoURLToSave)

            // Update Firebase Auth displayName (optional)
            if let user = Auth.auth().currentUser {
                let cr = user.createProfileChangeRequest()
                cr.displayName = displayName
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                    cr.commitChanges { err in
                        if let err { cont.resume(throwing: err) } else { cont.resume(returning: ()) }
                    }
                }
            }

            // Update local UI state immediately
            if let newURL = photoURLToSave {
                currentPhotoURL = newURL
            }
            pickedImageData = nil
            pickedItem = nil

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func compressJPEGIfNeeded(_ data: Data) -> Data {
        if let img = UIImage(data: data) {
            return img.jpegData(compressionQuality: 0.85) ?? data
        }
        return data
    }
}
