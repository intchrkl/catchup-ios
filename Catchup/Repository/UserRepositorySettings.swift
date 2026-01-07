//
//  UserRepositorySettings.swift
//  Catchup
//
//  Created by Nick Jitjang on 11/19/25.
//

import FirebaseFirestore

extension UsersRepository {
    /// Updates only the nested settings (and updatedAt).
    func updateSettings(uid: String,
                        pushEnabled: Bool? = nil,
                        inAppNotification: Bool? = nil,
                        timezone: String? = nil) async throws {
        let db = Firestore.firestore()
        var data: [String: Any] = ["updatedAt": Timestamp(date: Date())]
        if let pushEnabled        { data["settings.pushEnabled"]        = pushEnabled }
        if let inAppNotification  { data["settings.inAppNotification"]  = inAppNotification }
        if let timezone           { data["settings.timezone"]           = timezone }
        try await db.document("users/\(uid)").setData(data, merge: true)
    }
}
