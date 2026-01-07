//
//  FirebaseService.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import FirebaseAuth
import FirebaseFirestore

final class FirebaseService {
    static let shared = FirebaseService()
    let auth: Auth
    let db: Firestore

    private init() {
        self.auth = Auth.auth()
        self.db = Firestore.firestore()
        let settings = db.settings as! FirestoreSettings
        settings.isPersistenceEnabled = true
        db.settings = settings
    }
}
