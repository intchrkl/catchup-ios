//
//  StorageService.swift
//  Catchup
//
//  Created by Nick Jitjang on 11/9/25.
//

import Foundation
import FirebaseStorage

final class StorageService {
    static let shared = StorageService()
    private init() {}
    private let bucket = Storage.storage()

    /// Upload avatar bytes and return a public HTTPS download URL string.
    func uploadAvatar(uid: String, data: Data, contentType: String = "image/jpeg") async throws -> String {
        let ref = bucket.reference(withPath: "avatars/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}
