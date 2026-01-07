//
//  CatchupApp.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import SwiftUI
import FirebaseCore

@main
struct CatchUpApp: App {
    @StateObject private var session = SessionController()
    @StateObject private var auth = AuthController()
    

    init() {
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        NotificationService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(auth)
        }
    }
}
